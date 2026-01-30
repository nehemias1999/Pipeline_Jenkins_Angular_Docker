#!/usr/bin/env bash
set -euo pipefail

# Lista de repositorios/locales a procesar
repos=(
  "angular_application"
)

echo "Eliminando imagenes locales, dejando solo las 3 mas recientes..."
for repo in "${repos[@]}"; do
  echo
  echo "Procesando repo: $repo"

  # 1) Obtener lista de los nombres de las imagenes y sub tags
  mapfile -t images_names < <(
    docker images "$repo" --format "{{.Repository}}:{{.Tag}}" \
      | sort -r
  )

  total=${#images_names[@]}
  echo "Total de imagenes encontradas: $total"

  # 2) Si hay 3 o menos, no eliminar nada
  if (( total <= 3 )); then
    echo "Hay $total imagenes (<=3); no se elimina nada."
    continue
  fi

  # 3) Construir lista de image_names a eliminar (desde el 4° en adelante)
  images_to_delete=( "${images_names[@]:3}" )
  echo "Eliminando ${#images_to_delete[@]} imagenes antiguas de $repo..."

  echo "Total de imagenes: ${images_names[@]}"
  echo "Total de imagenes a borrar: ${images_to_delete[@]}"

  # 4) Borrar imágenes antiguas una por una
  for image_name in "${images_to_delete[@]}"; do
    echo "Eliminando imagen $image_name..."
    docker rmi -f "$image_name" || echo "No se pudo eliminar la imagen $image_name."
  done

done

echo
echo "Proceso completado: solo se conservaron las 3 imagenes mas recientes de cada repo."
