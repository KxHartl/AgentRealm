#!/usr/bin/env bash
set -euo pipefail

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
manifest="${root_dir}/config/requirements.list"

INSTALL_MODE=false
if [[ "${1:-}" == "--install" ]]; then INSTALL_MODE=true; fi

# If manifest isn't in repo root, try relative lookup
if [[ ! -f "$manifest" ]]; then
  if [[ -f "../../config/requirements.list" ]]; then
    root_dir="$(cd ../../ && pwd)"
    manifest="${root_dir}/config/requirements.list"
  fi
fi

if [[ ! -f "$manifest" ]]; then
  echo "Requirement manifest not found: $manifest"
  exit 2
fi

status=0
printf '%-10s %-14s %-10s %s\n' "SCOPE" "NAME" "STATUS" "DETAILS"

while IFS='|' read -r scope name command required min_version install_hint notes; do
  [[ -z "${scope// }" ]] && continue
  [[ "$scope" == \#* ]] && continue

  if command -v "$command" >/dev/null 2>&1; then
    printf '%-10s %-14s %-10s %s\n' "$scope" "$name" "OK" "$notes"
  else
    printf '%-10s %-14s %-10s %s (%s)\n' "$scope" "$name" "MISSING" "$notes" "$install_hint"
    if $INSTALL_MODE; then
      # Try to extract installer id from the hint: e.g. "Install Git.Git" -> Git.Git
      installer_pkg=""
      if [[ "$install_hint" =~ Install[[:space:]]+(.+) ]]; then
        installer_pkg="${BASH_REMATCH[1]}"
      fi

      echo "Attempting install for $name using available package manager..."
      if command -v winget >/dev/null 2>&1; then
        if [[ -n "$installer_pkg" ]]; then
          winget install --id "$installer_pkg" --silent --accept-package-agreements --accept-source-agreements || status=1
        else
          echo "winget available but no installer id found for $name; skipping automated install."; status=1
        fi
      elif command -v brew >/dev/null 2>&1; then
        # brew typically uses simple package names
        if [[ -n "$installer_pkg" ]]; then
          brew install "$installer_pkg" || status=1
        else
          brew install "$name" || status=1
        fi
      elif command -v apt-get >/dev/null 2>&1; then
        if [[ -n "$installer_pkg" ]]; then
          sudo apt-get update && sudo apt-get install -y "$installer_pkg" || status=1
        else
          sudo apt-get update && sudo apt-get install -y "$name" || status=1
        fi
      else
        echo "No supported package manager found for automated install. Please install $name manually."; status=1
      fi
    else
      if [[ "$required" != "optional" && "$required" != "recommended" ]]; then
        status=1
      fi
    fi
  fi
done < "$manifest"

exit "$status"
