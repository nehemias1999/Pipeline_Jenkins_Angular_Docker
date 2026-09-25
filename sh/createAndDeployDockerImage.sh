#!/usr/bin/env bash
# ==============================================================================
# Description: Actualiza el tag DOCKER_IMAGE_TAG por clave en el archivo .var
#   remoto, detiene los contenedores y levanta la nueva version con
#   docker compose. Espejo portable del .bat original para agentes Linux.
# Author: Pipeline_Jenkins_Angular_Docker maintainers
# Usage: ./createAndDeployDockerImage.sh <SSHPrivateKeyPath> <SSHUser> <SSHHost> <RemoteRepositoryPath> <DockerImageTag> <EnvFile> <DockerComposeFile>
# Env Vars: ninguna requerida (todo por argumentos).
# Dependencies: bash, ssh (OpenSSH); en remoto: awk, grep, docker compose
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
Usage: ./createAndDeployDockerImage.sh <SSHPrivateKeyPath> <SSHUser> <SSHHost> <RemoteRepositoryPath> <DockerImageTag> <EnvFile> <DockerComposeFile>
  Actualiza DOCKER_IMAGE_TAG por clave y redespliega con docker compose.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 7 ]; then
  echo "Usage: ./createAndDeployDockerImage.sh <SSHPrivateKeyPath> <SSHUser> <SSHHost> <RemoteRepositoryPath> <DockerImageTag> <EnvFile> <DockerComposeFile>" >&2
  exit 2
fi

ssh_key="$1"
ssh_user="$2"
ssh_host="$3"
remote_path="$4"
docker_tag="$5"
env_file="$6"
compose_file="$7"

if [ -z "$ssh_key" ] || [ -z "$ssh_user" ] || [ -z "$ssh_host" ] || [ -z "$remote_path" ] || [ -z "$docker_tag" ] || [ -z "$env_file" ] || [ -z "$compose_file" ]; then
  echo "Usage: ./createAndDeployDockerImage.sh <SSHPrivateKeyPath> <SSHUser> <SSHHost> <RemoteRepositoryPath> <DockerImageTag> <EnvFile> <DockerComposeFile> (ningun argumento vacio)" >&2
  exit 2
fi

ssh_opts=(-o StrictHostKeyChecking=yes -o BatchMode=yes -i "$ssh_key")
target="${ssh_user}@${ssh_host}"

log "Updating DOCKER_IMAGE_TAG=${docker_tag} in ${env_file} (by key)"
ssh "${ssh_opts[@]}" "$target" "cd \"${remote_path}\" && awk -v k=DOCKER_IMAGE_TAG -v v=\"${docker_tag}\" 'BEGIN{FS=OFS=\"=\"} \$1==k{\$2=v;f=1}{print} END{if(!f)print k\"=\"v}' \"${env_file}\" > \"${env_file}.tmp\" && mv \"${env_file}.tmp\" \"${env_file}\" && grep \"^DOCKER_IMAGE_TAG=\" \"${env_file}\""

log "Stopping services with ${compose_file}"
ssh "${ssh_opts[@]}" "$target" "cd \"${remote_path}\" && docker compose -f \"${compose_file}\" --env-file=\"${env_file}\" down"

log "Starting services with ${compose_file}"
ssh "${ssh_opts[@]}" "$target" "cd \"${remote_path}\" && docker compose -f \"${compose_file}\" --env-file=\"${env_file}\" up --build -d; echo \$?"

log "Deployed tag: ${docker_tag}"
