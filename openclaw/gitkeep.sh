#!/usr/bin/env bash
# Usage: ./gitkeep.sh [directory]
# If no directory is provided, the current directory is used.

TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
  echo "Error: '$TARGET' is not a directory."
  exit 1
fi

find "$TARGET" -type d | while read -r dir; do
  # Check if the directory has no files (ignore other directories)
  if [ -z "$(find "$dir" -maxdepth 1 -not -type d)" ]; then
    touch "$dir/.gitkeep"
    echo "Created: $dir/.gitkeep"
  fi
done
