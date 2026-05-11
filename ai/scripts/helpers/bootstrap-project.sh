#!/usr/bin/env bash
set -euo pipefail

project_name=""
ide="vscode"
rag="none"
brain=""

usage() {
  echo "Usage: $0 --name <project-name> [--ide <vscode|antigravity>] [--rag <none|cloud|local>] [--brain <repo-url>]"
  echo ""
  echo "RAG Modes:"
  echo "  none   (default) No RAG. Zero Python overhead."
  echo "  cloud  Gemini API embeddings. ~200 MB footprint. Requires GOOGLE_API_KEY."
  echo "  local  Local sentence-transformers model. ~1.2 GB footprint. Works offline."
  echo ""
  echo "Global Brain:"
  echo "  --brain <url>  Link a shared knowledge repository into ai/knowledge/global/"
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
    --rag)
      rag="$2"
      shift 2
      ;;
    --brain)
      brain="$2"
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

requirements_manifest="ai/config/requirements.list"

# Backup important config files before modifying
cp ai/config/project.yaml ai/config/project.yaml.bak || true
cp STATE.md STATE.md.bak || true

# Update project.yaml
sed -i "s/^name: .*/name: \"${project_name}\"/" ai/config/project.yaml
sed -i "s/^default_ide: .*/default_ide: \"${ide}\" # vscode | antigravity/" ai/config/project.yaml
sed -i "s/^rag_mode: .*/rag_mode: \"${rag}\" # none | cloud | local/" ai/config/project.yaml

# Update STATE.md (Full Reset for new project)
curr_date=$(date +%Y-%m-%d)
cat <<EOF > STATE.md
# STATE.md

## Project info

- Name: ${project_name}
- Type: seminar
- Owner: $(whoami)

## Requirements

- Manifest: ai/config/requirements.list
- Check command: ai/scripts/helpers/check-requirements.sh
- Installation status: _Not checked yet._

## Current focus
- project-init

- **Project initialized**: Started new project based on AgentRealm V2 template.

## Backlog

- [ ] Add project source files to src/
- [ ] Add research documents to data/rag/sources/
- [ ] Define project tasks in docs/

## Changelog

- ${curr_date}: **Project Initialized** — Template bootstrapped with name: ${project_name}
EOF

# Update README.md
if [[ -f README.md ]]; then
  sed -i "s/^# AgentRealm/# ${project_name}/" README.md
  sed -i "s/Universal template for \*\*projects, seminars, and research\*\*/Project for **${project_name}**, built using AgentRealm template/" README.md
fi

if ! grep -q '^  requirements:' ai/config/project.yaml; then
  printf '\n  requirements: "%s"\n' "$requirements_manifest" >> ai/config/project.yaml
fi

if ! grep -q '^## Requirements' STATE.md; then
  cat <<'EOF' >> STATE.md

## Requirements

- Manifest: ai/config/requirements.list
- Check command: ai/scripts/helpers/check-requirements.sh
- Installation status: _Not checked yet._
EOF
fi

mkdir -p ai/worktrees

# 1. Check requirements
echo "Verifying project requirements..."
bash ./ai/scripts/helpers/check-requirements.sh || echo "Warning: Some requirements are missing."

# 2. Setup Python & install RAG deps based on mode
if command -v python3 >/dev/null 2>&1; then
  if [[ ! -d ".venv" ]]; then
    python3 -m venv .venv
    echo "Virtual environment created."
  fi

  # Install base requirements
  .venv/bin/pip install -r requirements.txt 2>/dev/null || true

  if [[ "$rag" == "cloud" ]]; then
    echo "Installing RAG Cloud dependencies (Gemini API embeddings)..."
    .venv/bin/pip install -r ai/config/requirements-rag-cloud.txt
    echo "RAG Cloud mode installed."
  elif [[ "$rag" == "local" ]]; then
    echo "Installing RAG Local dependencies (sentence-transformers)..."
    echo "This will download ~1 GB of PyTorch dependencies."
    .venv/bin/pip install -r ai/config/requirements-rag-local.txt
    echo "RAG Local mode installed."
  else
    echo "RAG disabled. No AI/ML packages installed."
  fi
fi

# Optional: Apply GitHub ruleset if 'gh' is logged in
echo "Checking GitHub CLI status..."
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    echo "Applying GitHub ruleset..."
    bash ./ai/scripts/helpers/apply-github-config.sh
  else
    echo "Not logged in to GitHub CLI. Skipping automatic ruleset application."
  fi
fi

# 3. Connect to Global Brain
if [[ -n "$brain" ]]; then
  echo "Connecting to Global Brain..."
  brain_path="ai/knowledge/global"
  if [[ ! -d "$brain_path" ]]; then
    git clone "$brain" "$brain_path"
    if [[ $? -eq 0 ]]; then
      echo "Global Brain connected successfully."
    else
      echo "Failed to clone Global Brain repository."
    fi
  else
    echo "Global Brain directory already exists. Skipping clone."
  fi
fi

echo ""
echo "Project bootstrapped."
echo "  Name: $project_name"
echo "  IDE:  $ide"
echo "  RAG:  $rag"
[[ -n "$brain" ]] && echo "  Brain: $brain"
echo "  Requirements: $requirements_manifest"

