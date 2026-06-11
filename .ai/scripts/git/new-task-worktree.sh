#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <task-slug>"
  exit 1
fi

slug="$1"
root_dir="$(git rev-parse --show-toplevel)"
branch="task/${slug}"
worktree="${root_dir}/.ai/worktrees/${slug}"

git -C "$root_dir" fetch --all --prune

if git -C "$root_dir" show-ref --verify --quiet "refs/heads/${branch}"; then
  git -C "$root_dir" worktree add "$worktree" "$branch"
else
  git -C "$root_dir" worktree add -b "$branch" "$worktree" main
fi

echo "Worktree created: $worktree"
echo "Branch: $branch"

# Ensure the new worktree is marked as safe
git config --global --add safe.directory "$worktree"

# Update STATE.md focus
state_file="${root_dir}/STATE.md"
if [[ -f "$state_file" ]]; then
  sed -i "/## Current focus/a - ${slug}" "$state_file"
  echo "Updated STATE.md focus with: ${slug}"
fi

# Check terminal settings
skip_terminal=$(grep "skip_external_terminal:" "$root_dir/.ai/config/project.yaml" | grep -oE "true|false" || echo "false")

if [[ "$skip_terminal" == "false" ]]; then
  echo "Opening external terminal..."
  if command -v x-terminal-emulator >/dev/null 2>&1; then
    x-terminal-emulator --working-directory="$worktree" &
  elif command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal --working-directory="$worktree" &
  elif command -v konsole >/dev/null 2>&1; then
    konsole --workdir "$worktree" &
  fi
fi

# Launch IDE
ide=$(grep "default_ide:" "$root_dir/.ai/config/project.yaml" | cut -d'"' -f2)

if [[ "$ide" == "vscode" ]]; then
  echo "Launching VS Code..."
  code "$worktree"
elif [[ "$ide" == "antigravity" ]]; then
  echo "Launching Antigravity..."
  if command -v antigravity >/dev/null 2>&1; then
    antigravity "$worktree"
  else
    echo "antigravity command not found. Using external terminal."
  fi
fi
