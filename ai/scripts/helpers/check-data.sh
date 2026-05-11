#!/usr/bin/env bash
# Data Integrity Check

lock=false
if [[ "${1:-}" == "--lock" ]]; then
  lock=true
fi

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root_dir"

raw_path="${root_dir}/data/process/raw"
manifest_path="${raw_path}/manifest.sha256"

if [[ ! -d "$raw_path" ]]; then
  echo "Warning: data/process/raw directory not found. Skipping integrity check."
  exit 0
fi

get_hashes() {
  find "$raw_path" -type f -not -name "manifest.sha256" -exec sha256sum {} + | sed "s|$raw_path/||"
}

if [[ "$lock" == true ]]; then
  echo "Locking data in $raw_path..."
  get_hashes > "$manifest_path"
  echo "Manifest created at $manifest_path"
  exit 0
fi

if [[ ! -f "$manifest_path" ]]; then
  echo "Warning: No manifest found in data/process/raw/. Run with --lock to secure data."
  exit 0
fi

echo "Verifying data integrity in data/process/raw/..."
current_hashes=$(get_hashes)
stored_hashes=$(cat "$manifest_path")

if [[ "$current_hashes" == "$stored_hashes" ]]; then
  echo "Data integrity verified."
else
  echo "CRITICAL: Data integrity breach!"
  exit 1
fi
