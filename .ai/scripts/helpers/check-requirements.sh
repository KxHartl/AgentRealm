#!/usr/bin/env bash
set -euo pipefail

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
manifest="${root_dir}/.ai/config/requirements.list"

if [[ ! -f "$manifest" ]]; then
  # If we are in .ai/scripts/helpers, try to find root
  if [[ -f "../../../.ai/config/requirements.list" ]]; then
    root_dir="../../.."
    manifest="${root_dir}/.ai/config/requirements.list"
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

# Function to check if a command or package is available
check_requirement() {
  local scope="$1"
  local name="$2"
  local command="$3"

  if [[ "$scope" == "python" ]]; then
    # Try to use the project's venv if it exists, otherwise system python
    local py_cmd="python"
    if [[ -f ".venv/bin/python" ]]; then
      py_cmd=".venv/bin/python"
    elif [[ -f ".venv/Scripts/python.exe" ]]; then
      py_cmd=".venv/Scripts/python.exe"
    elif command -v python3 >/dev/null 2>&1; then
      py_cmd="python3"
    fi
    
    $py_cmd -c "import $command" >/dev/null 2>&1
    return $?
  else
    # For global scope, we use command -v
    # Special check for Windows 'stubs'
    if [[ "$command" == "python" || "$command" == "python3" ]]; then
       if command -v "$command" >/dev/null 2>&1; then
          # Verify it's not the Microsoft Store stub
          $command --version >/dev/null 2>&1
          return $?
       fi
       return 1
    fi
    command -v "$command" >/dev/null 2>&1
    return $?
  fi
}

while IFS='|' read -r scope name command required min_version install_hint notes; do
  [[ -z "${scope// }" ]] && continue
  [[ "$scope" == \#* ]] && continue

  if check_requirement "$scope" "$name" "$command"; then
    printf '%-10s %-14s %-10s %s\n' "$scope" "$name" "OK" "$notes"
  else
    if [[ "$install_flag" == true ]]; then
      printf '%-10s %-14s %-10s %s\n' "$scope" "$name" "INSTALLING" "Attempting install..."
      if [[ "$scope" == "python" ]]; then
         local pip_cmd="pip"
         [[ -f ".venv/bin/pip" ]] && pip_cmd=".venv/bin/pip"
         [[ -f ".venv/Scripts/pip.exe" ]] && pip_cmd=".venv/Scripts/pip.exe"
         $pip_cmd install $name || true
      elif command -v brew >/dev/null 2>&1; then
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
