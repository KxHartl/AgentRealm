#!/usr/bin/env bash
# Project Dashboard

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root_dir"

echo -e "\e[44m\e[97m🌌 AgentRealm Project Dashboard\e[0m"
echo "==============================="

# 1. Project Info
project_name="Unknown"
if [[ -f "config/project.yaml" ]]; then
  project_name=$(grep "name:" config/project.yaml | sed 's/name: //;s/"//g')
fi
echo -e "Project: \e[36m$project_name\e[0m"
echo -e "Root: $root_dir"
echo ""

# 2. Current Focus
focus=$(grep -A 1 "## Current focus" STATE.md | tail -n 1 | sed 's/- //')
echo -e "\e[33m🎯 Current Focus:\e[0m"
echo "   $focus"
echo ""

# 3. Active Worktrees
echo -e "\e[36m🛡️ Active Task Sandboxes (.agents/):\e[0m"
git worktree list | grep ".agents" | while read -r line; do
  echo "   - $line"
done || echo "   (None)"
echo ""

# 4. System Health
echo -e "\e[36m🔍 System Health:\e[0m"
bash ./scripts/helpers/check-requirements.sh | tail -n +2 | while read -r line; do
  if [[ "$line" == *"MISSING"* ]]; then
    echo -e "   ❌ $line"
  fi
done

echo ""
echo "Tip: Run './scripts/helpers/check-all.sh' for a full sanity check."
