#!/usr/bin/env bash
set -euo pipefail

project_name=""
ide="vscode"

usage() {
  echo "Usage: $0 --name <project-name> [--ide <vscode|antigravity>]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      project_name="$2"
      shift 2
      ;;
    --ide)
      ide="$2"
      shift 2
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$project_name" ]]; then
  usage
  exit 1
fi

requirements_manifest="config/requirements.list"

# Backup important config files before modifying
cp config/project.yaml config/project.yaml.bak || true
cp STATE.md STATE.md.bak || true

sed -i "s/^name: .*/name: \"${project_name}\"/" config/project.yaml
sed -i "s/^default_ide: .*/default_ide: \"${ide}\" # vscode | antigravity/" config/project.yaml
sed -i "s/^- Name: .*/- Name: ${project_name}/" STATE.md

if ! grep -q '^  requirements:' config/project.yaml; then
  printf '\n  requirements: "%s"\n' "$requirements_manifest" >> config/project.yaml
fi

if ! grep -q '^## Requirements' STATE.md; then
  cat <<'EOF' >> STATE.md

## Requirements

- Manifest: config/requirements.list
- Check command: scripts/helpers/check-requirements.sh
- Installation status: _Not checked yet._
EOF
fi

mkdir -p .agents

# 1. Check requirements
echo "Verifying project requirements..."
bash ./scripts/helpers/check-requirements.sh || echo "Warning: Some requirements are missing. Run with --install if you have brew or apt-get."

# Optional: Apply GitHub ruleset if 'gh' is logged in
echo "Checking GitHub CLI status..."
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "Applying GitHub ruleset..."
    bash ./scripts/helpers/apply-github-config.sh
  else
    echo "Not logged in to GitHub CLI. Skipping automatic ruleset application."
  fi
fi

echo "Project bootstrapped."
echo "Name: $project_name"
echo "IDE: $ide"
echo "Requirements manifest: $requirements_manifest"
