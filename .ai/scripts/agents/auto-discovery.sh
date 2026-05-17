#!/usr/bin/env bash
# Brain Auto-Discovery
set -euo pipefail

worktree_path="${1:-}"
if [[ -z "$worktree_path" ]]; then
  echo "Usage: $0 <path_to_completed_worktree>"
  exit 1
fi

echo "--- 🧠 Brain Auto-Discovery ---"
root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

python_script="${root_dir}/.ai/scripts/agents/auto_discovery.py"
if [[ -f "$python_script" ]]; then
  python_cmd="python3"
  [[ -f "${root_dir}/.venv/bin/python" ]] && python_cmd="${root_dir}/.venv/bin/python"

  echo "Scanning ${worktree_path} for new skills..."
  $python_cmd "$python_script" "$worktree_path"

  sync_script="${root_dir}/.ai/scripts/agents/sync-brain.sh"
  if [[ -f "$sync_script" ]]; then
    echo "Syncing AgentBrain to update local caches..."
    bash "$sync_script"
  fi
else
  echo "Auto-discovery helper python script not found."
  exit 2
fi
