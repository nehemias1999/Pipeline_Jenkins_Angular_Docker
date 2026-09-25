#!/usr/bin/env bash
# ==============================================================================
# Description: Actualiza (o agrega) una clave KEY=VALUE en un archivo .var por
#   clave y de forma idempotente; nunca por posicion de linea.
# Author: Pipeline_Jenkins_Angular_Docker maintainers
# Usage: ./updateVarByKey.sh <var-file> <KEY> <VALUE>
# Env Vars: ninguna requerida.
# Dependencies: awk, grep, mktemp
# Exit codes: 0 ok; 2 uso/argumentos invalidos; 1 error operativo.
# ==============================================================================

set -euo pipefail

# log: imprime un mensaje con timestamp ISO-8601 UTC a STDOUT. Args: $1 mensaje.
log() {
  printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*"
}

# usage: imprime la ayuda a STDOUT.
usage() {
  cat <<'EOF'
Usage: ./updateVarByKey.sh <var-file> <KEY> <VALUE>
  Actualiza KEY=VALUE en <var-file> por clave (idempotente, una sola linea ^KEY=).
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 3 ]; then
  echo "Usage: ./updateVarByKey.sh <var-file> <KEY> <VALUE>" >&2
  exit 2
fi

var_file="$1"
key="$2"
value="$3"

if [ -z "$var_file" ] || [ -z "$key" ]; then
  echo "Usage: ./updateVarByKey.sh <var-file> <KEY> <VALUE> (var-file y KEY no vacios)" >&2
  exit 2
fi

if [ ! -f "$var_file" ]; then
  echo "ERROR: no existe el archivo: $var_file" >&2
  exit 1
fi

tmp_file="$(mktemp)"
awk -v k="$key" -v v="$value" 'BEGIN{FS=OFS="="} $1==k{$2=v;f=1}{print} END{if(!f)print k"="v}' "$var_file" > "$tmp_file"
mv -- "$tmp_file" "$var_file"
log "Updated ${key}=${value} in ${var_file}"
grep "^${key}=" "$var_file"
