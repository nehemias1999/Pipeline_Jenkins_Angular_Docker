#!/usr/bin/env bash
# ==============================================================================
# Description: Genera build-info.json con las 5 claves de trazabilidad
#   (commit, branch, build_tag, image, timestamp UTC ISO-8601) y valida que el
#   JSON sea parseable. El pipeline lo archiva como artefacto de auditoria.
# Author: Pipeline_Jenkins_Angular_Docker maintainers
# Usage: ./writeBuildInfo.sh <commit> <branch> <build-tag> <image> <output>
# Env Vars: ninguna requerida (todo por argumentos).
# Dependencies: bash, python3 o jq (para validar el JSON generado)
# Output: escribe el archivo JSON en <output>. Exit codes: 0 ok; 2 uso invalido; 1 JSON invalido.
# ==============================================================================

set -euo pipefail

# usage: imprime la ayuda a STDOUT.
usage() {
  cat <<'EOF'
Usage: ./writeBuildInfo.sh <commit> <branch> <build-tag> <image> <output>
  Genera build-info.json con {commit, branch, build_tag, image, timestamp}.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 5 ]; then
  echo "Usage: ./writeBuildInfo.sh <commit> <branch> <build-tag> <image> <output>" >&2
  exit 2
fi

commit="$1"
branch="$2"
build_tag="$3"
image="$4"
output="$5"

if [ -z "$commit" ] || [ -z "$branch" ] || [ -z "$build_tag" ] || [ -z "$image" ] || [ -z "$output" ]; then
  echo "Usage: ./writeBuildInfo.sh <commit> <branch> <build-tag> <image> <output> (ningun argumento vacio)" >&2
  exit 2
fi

timestamp="$(date -u +%FT%TZ)"

# json_escape: escapa comillas y barras para interpolar seguro. Args: $1 texto.
json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

printf '{"commit": "%s", "branch": "%s", "build_tag": "%s", "image": "%s", "timestamp": "%s"}\n' \
  "$(json_escape "$commit")" \
  "$(json_escape "$branch")" \
  "$(json_escape "$build_tag")" \
  "$(json_escape "$image")" \
  "$timestamp" > "$output"

# validate_json: verifica que el archivo sea JSON parseable. Args: $1 archivo.
validate_json() {
  if command -v jq >/dev/null 2>&1; then
    jq empty "$1"
  else
    python3 -m json.tool "$1" >/dev/null
  fi
}

if ! validate_json "$output"; then
  echo "ERROR: JSON invalido en ${output}" >&2
  exit 1
fi

printf 'build-info written to %s\n' "$output"
