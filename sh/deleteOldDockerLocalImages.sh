#!/usr/bin/env bash
set -euo pipefail

# List of repositories/local images to process
repos=(
  "angular_application"
)

echo "Removing local images, keeping only the 3 most recent ones..."
for repo in "${repos[@]}"; do
  echo
  echo "Processing repository: $repo"

  # 1) Get the list of image names and tags
  mapfile -t images_names < <(
    docker images "$repo" --format "{{.Repository}}:{{.Tag}}" \
      | sort -r
  )

  total=${#images_names[@]}
  echo "Total images found: $total"

  # 2) If there are 3 or fewer images, do not remove anything
  if (( total <= 3 )); then
    echo "There are $total images (<=3); nothing will be removed."
    continue
  fi

  # 3) Build the list of image names to delete (from the 4th onward)
  images_to_delete=( "${images_names[@]:3}" )
  echo "Removing ${#images_to_delete[@]} old images from $repo..."

  echo "All images: ${images_names[@]}"
  echo "Images to be deleted: ${images_to_delete[@]}"

  # 4) Remove old images one by one
  for image_name in "${images_to_delete[@]}"; do
    echo "Removing image $image_name..."
    docker rmi -f "$image_name" || echo "Failed to remove image $image_name."
  done

done

echo
echo "Process completed: only the 3 most recent images of each repository were kept."
