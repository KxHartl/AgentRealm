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

echo "Project bootstrapped."
echo "Name: $project_name"
echo "IDE: $ide"
echo "Requirements manifest: $requirements_manifest"
