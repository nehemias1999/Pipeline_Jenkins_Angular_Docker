#!/usr/bin/env bash
# ==============================================================================
# Description: Calcula el tag de imagen trazable '1.<build>-<short-sha>' a
#   partir del numero de build y del SHA completo del commit. Sin argumentos
#   usa $BUILD_NUMBER y $GIT_COMMIT del entorno (Jenkins checkout scm).
# Author: Pipeline_Jenkins_Angular_Docker maintainers
# Usage: ./computeVersion.sh <build-number> <full-sha>
# Env Vars: BUILD_NUMBER (fallback si no hay args), GIT_COMMIT (fallback si no hay args)
# Dependencies: bash
# Output: imprime el tag en STDOUT. Exit codes: 0 ok; 2 uso/formato invalido.
# ==============================================================================

set -euo pipefail

# usage: imprime la ayuda a STDOUT.
usage() {
  cat <<'EOF'
Usage: ./computeVersion.sh <build-number> <full-sha>
  Calcula el tag trazable '1.<build>-<short-sha>' (ej: 1.42-abc1234).
  Sin argumentos usa $BUILD_NUMBER y $GIT_COMMIT del entorno.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

build_number="${1:-${BUILD_NUMBER:-}}"
full_sha="${2:-${GIT_COMMIT:-}}"

# invalid: falla con Usage en STDERR y exit 2. Args: $1 motivo.
invalid() {
  echo "Usage: ./computeVersion.sh <build-number> <full-sha> ($1)" >&2
  exit 2
}

[ -n "$build_number" ] || invalid "falta build-number (arg o \$BUILD_NUMBER)"
[ -n "$full_sha" ] || invalid "falta full-sha (arg o \$GIT_COMMIT)"

[[ "$build_number" =~ ^[0-9]+$ ]] || invalid "build-number debe ser numerico"
short_sha="${full_sha:0:7}"
[[ "$short_sha" =~ ^[0-9a-fA-F]{7}$ ]] || invalid "sha debe iniciar con 7 hex"

tag="1.${build_number}-${short_sha}"
[[ "$tag" =~ ^[0-9]+\.[0-9]+-[0-9a-fA-F]{7}$ ]] || invalid "tag invalido: ${tag}"

printf '%s\n' "$tag"
