#!/usr/bin/env bash
set -euo pipefail

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
manifest="${root_dir}/config/requirements.list"

if [[ ! -f "$manifest" ]]; then
  # If we are in scripts/helpers, try one level up
  if [[ -f "../../config/requirements.list" ]]; then
    root_dir="../.."
    manifest="${root_dir}/config/requirements.list"
  fi
fi

if [[ ! -f "$manifest" ]]; then
  echo "Requirement manifest not found: $manifest"
  exit 2
fi

status=0
printf '%-10s %-14s %-10s %s\n' "SCOPE" "NAME" "STATUS" "DETAILS"

install_flag=false
if [[ "${1:-}" == "--install" ]]; then
  install_flag=true
fi

while IFS='|' read -r scope name command required min_version install_hint notes; do
  [[ -z "${scope// }" ]] && continue
  [[ "$scope" == \#* ]] && continue

  if command -v "$command" >/dev/null 2>&1; then
    printf '%-10s %-14s %-10s %s\n' "$scope" "$name" "OK" "$notes"
  else
    if [[ "$install_flag" == true ]]; then
      printf '%-10s %-14s %-10s %s\n' "$scope" "$name" "INSTALLING" "Attempting install..."
      if command -v brew >/dev/null 2>&1; then
        brew install "$name" || true
      elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y "$name" || true
      fi
    else
      printf '%-10s %-14s %-10s %s (%s)\n' "$scope" "$name" "MISSING" "$notes" "$install_hint"
      if [[ "$required" != "optional" && "$required" != "recommended" ]]; then
        status=1
      fi
    fi
  fi
done < "$manifest"

exit "$status"
