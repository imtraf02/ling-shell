#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"

mapfile -d '' all_files < <(
    find "$ROOT_DIR" -type f -name "*.qml" -print0
)

if [ "${#all_files[@]}" -eq 0 ]; then
    echo "No QML files found in: $ROOT_DIR"
    exit 0
fi

echo "Formatting ${#all_files[@]} QML files..."

printf '%s\0' "${all_files[@]}" | \
    xargs -0 qmlformat -i -w 2 -W 360

echo "Done."
