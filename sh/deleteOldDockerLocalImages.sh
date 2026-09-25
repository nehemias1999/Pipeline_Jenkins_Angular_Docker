#!/usr/bin/env bash
# ==============================================================================
# Description: Elimina imagenes Docker locales viejas conservando solo las 3
#   mas recientes por repositorio para optimizar disco. La retencion (3) no
#   se cambia; este cambio solo anade validacion y logging con timestamps.
# Author: Pipeline_Jenkins_Angular_Docker maintainers
# Usage: ./deleteOldDockerLocalImages.sh (sin argumentos)
# Env Vars: ninguna requerida.
# Dependencies: bash, docker, sort
# Exit codes: 0 ok; 2 uso/argumentos invalidos.
# ==============================================================================

set -euo pipefail

# log: imprime un mensaje con timestamp ISO-8601 UTC a STDOUT. Args: $1 mensaje.
log() {
  printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*"
}

# usage: imprime la ayuda a STDOUT.
usage() {
  cat <<'EOF'
Usage: ./deleteOldDockerLocalImages.sh (sin argumentos)
  Elimina imagenes locales viejas, conserva las 3 mas recientes por repo.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 0 ]; then
  echo "Usage: ./deleteOldDockerLocalImages.sh (sin argumentos)" >&2
  exit 2
fi

# List of repositories/local images to process
repos=(
  "angular_application"
)

log "Removing local images, keeping only the 3 most recent ones..."
for repo in "${repos[@]}"; do
  log ""
  log "Processing repository: $repo"

  # 1) Get the list of image names and tags
  mapfile -t images_names < <(
    docker images "$repo" --format "{{.Repository}}:{{.Tag}}" \
      | sort -r
  )

  total=${#images_names[@]}
  log "Total images found: $total"

  # 2) If there are 3 or fewer images, do not remove anything
  if (( total <= 3 )); then
    log "There are $total images (<=3); nothing will be removed."
    continue
  fi

  # 3) Build the list of image names to delete (from the 4th onward)
  images_to_delete=( "${images_names[@]:3}" )
  log "Removing ${#images_to_delete[@]} old images from $repo..."

  log "All images: ${images_names[*]}"
  log "Images to be deleted: ${images_to_delete[*]}"

  # 4) Remove old images one by one
  for image_name in "${images_to_delete[@]}"; do
    log "Removing image $image_name..."
    docker rmi -f "$image_name" || log "Failed to remove image $image_name."
  done

done

log ""
log "Process completed: only the 3 most recent images of each repository were kept."
