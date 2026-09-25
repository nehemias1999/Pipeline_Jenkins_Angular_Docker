#!/usr/bin/env bash
# ==============================================================================
# Description: Prepara el paquete de despliegue copiando los archivos
#   requeridos al directorio 'deploy' y transfiriendolos al servidor remoto
#   via SCP. Espejo portable del .bat original para agentes Linux.
# Author: Pipeline_Jenkins_Angular_Docker maintainers
# Usage: ./setContentDockerImage.sh <PipelinePath> <ApplicationPath> <SSHPrivateKeyPath> <SSHUser> <SSHHost> <RepositoryPath>
# Env Vars: ninguna requerida (todo por argumentos).
# Dependencies: bash, cp, mkdir, ssh, scp (OpenSSH)
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
Usage: ./setContentDockerImage.sh <PipelinePath> <ApplicationPath> <SSHPrivateKeyPath> <SSHUser> <SSHHost> <RepositoryPath>
  Prepara 'deploy' y lo transfiere al servidor remoto via SCP.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 6 ]; then
  echo "Usage: ./setContentDockerImage.sh <PipelinePath> <ApplicationPath> <SSHPrivateKeyPath> <SSHUser> <SSHHost> <RepositoryPath>" >&2
  exit 2
fi

pipeline_path="$1"
application_path="$2"
ssh_key="$3"
ssh_user="$4"
ssh_host="$5"
repository_path="$6"

if [ -z "$pipeline_path" ] || [ -z "$application_path" ] || [ -z "$ssh_key" ] || [ -z "$ssh_user" ] || [ -z "$ssh_host" ] || [ -z "$repository_path" ]; then
  echo "Usage: ./setContentDockerImage.sh <PipelinePath> <ApplicationPath> <SSHPrivateKeyPath> <SSHUser> <SSHHost> <RepositoryPath> (ningun argumento vacio)" >&2
  exit 2
fi

ssh_opts=(-o StrictHostKeyChecking=yes -o BatchMode=yes -i "$ssh_key")
target="${ssh_user}@${ssh_host}"

log "Preparing deploy package in ${pipeline_path}/deploy"
mkdir -p -- "${pipeline_path}/deploy"

# copy_file: copia un archivo si existe; si no, advierte y sigue. Args: $1 origen, $2 destino.
copy_file() {
  if [ -e "$1" ]; then
    cp -- "$1" "$2"
    log "Copied $1 -> $2"
  else
    log "WARNING: missing $1, skipped"
  fi
}

if [ -d "${application_path}/src" ]; then
  mkdir -p -- "${pipeline_path}/deploy/src"
  cp -r -- "${application_path}/src/." "${pipeline_path}/deploy/src/"
  log "Copied ${application_path}/src -> ${pipeline_path}/deploy/src"
else
  log "WARNING: missing ${application_path}/src, skipped"
fi

for f in angular.json package.json package-lock.json tsconfig.app.json tsconfig.json tsconfig.spec.json; do
  copy_file "${application_path}/${f}" "${pipeline_path}/deploy/"
done

if [ -d "${pipeline_path}/docker" ]; then
  cp -r -- "${pipeline_path}/docker/." "${pipeline_path}/deploy/"
  log "Copied ${pipeline_path}/docker -> ${pipeline_path}/deploy"
else
  log "WARNING: missing ${pipeline_path}/docker, skipped"
fi

if [ -d "${pipeline_path}/sh" ]; then
  mkdir -p -- "${pipeline_path}/deploy/sh"
  cp -r -- "${pipeline_path}/sh/." "${pipeline_path}/deploy/sh/"
  log "Copied ${pipeline_path}/sh -> ${pipeline_path}/deploy/sh"
else
  log "WARNING: missing ${pipeline_path}/sh, skipped"
fi

log "Cleaning remote directory ${repository_path} (guarded rm)"
ssh "${ssh_opts[@]}" "$target" "[ -n '${repository_path}' ] && [ '${repository_path}' != '/' ] && rm -rf -- '${repository_path}/'*"

log "Copying deploy folder to ${target}:${repository_path}"
scp -r "${ssh_opts[@]}" "${pipeline_path}/deploy/." "${target}:${repository_path}/"

log "Deploy package transferred to ${target}:${repository_path}"
