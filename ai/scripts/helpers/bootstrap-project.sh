#!/usr/bin/env bash
set -euo pipefail

project_name=""
ide="vscode"
rag="none"

usage() {
  echo "Usage: $0 --name <project-name> [--ide <vscode|antigravity>] [--rag <none|cloud|local>]"
  echo ""
  echo "RAG Modes:"
  echo "  none   (default) No RAG. Zero Python overhead."
  echo "  cloud  Gemini API embeddings. ~200 MB footprint. Requires GOOGLE_API_KEY."
  echo "  local  Local sentence-transformers model. ~1.2 GB footprint. Works offline."
  echo ""
  echo "Global Brain:"
  echo "  This project automatically connects to ~/.agentbrain as the SSOT."
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

# 1. Update project.yaml & STATE.md
echo "Updating project metadata..."
sed -i "s/^name: .*/name: \"${project_name}\"/" ai/config/project.yaml
sed -i "s/^default_ide: .*/default_ide: \"${ide}\" # vscode | antigravity/" ai/config/project.yaml
sed -i "s/^rag_mode: .*/rag_mode: \"${rag}\" # none | cloud | local/" ai/config/project.yaml

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

- **AgentRealm V2.4**: Integrated Global AgentBrain (~/.agentbrain).

## Backlog

- [ ] Add project source files to src/
- [ ] Add research documents to data/rag/sources/
- [ ] Sync Global Brain skills: ./ai/scripts/agents/sync-brain.sh

## Changelog

- ${curr_date}: **Project Initialized** — V2.4 Architecture with Global AgentBrain.
EOF

# 2. Setup .env from .env.example
if [[ ! -f .env ]]; then
  echo "Creating .env from .env.example..."
  cp .env.example .env
fi

# 3. Resolve and Verify Global Brain
brain_path="${HOME}/.agentbrain"

echo "Connecting to Global AgentBrain at ${brain_path}..."
if [[ -d "$brain_path" ]]; then
  if [[ -d "${brain_path}/.git" ]]; then
    echo "Brain is a git repo. Pulling latest skills..."
    cd "$brain_path" && git pull origin main && cd - > /dev/null
  fi
  echo "Global Brain connected."
else
  echo "Warning: Global Brain not found at ${brain_path}. RAG will only use local project data."
fi

# Update README.md
if [[ -f README.md ]]; then
  sed -i "s/^# AgentRealm/# ${project_name}/" README.md
  sed -i "s/Universal template for \*\*projects, seminars, and research\*\*/Project for **${project_name}**, built using AgentRealm template/" README.md
fi

mkdir -p ai/worktrees

# 4. Check requirements
echo "Verifying project requirements..."
bash ./ai/scripts/helpers/check-requirements.sh || echo "Warning: Some requirements are missing."

# 5. Setup Python & install RAG deps
get_python() {
  if command -v python >/dev/null 2>&1 && python -c "import sys" >/dev/null 2>&1; then
    echo "python"
  elif command -v python3 >/dev/null 2>&1 && python3 -c "import sys" >/dev/null 2>&1; then
    echo "python3"
  else
    echo ""
  fi
}

PY_CMD=$(get_python)
if [[ -n "$PY_CMD" ]]; then
  if [[ ! -d ".venv" ]]; then
    $PY_CMD -m venv .venv
    echo "Virtual environment created."
  fi

  # Determine correct path to pip
  PIP_CMD=".venv/bin/pip"
  [[ -f ".venv/Scripts/pip.exe" ]] && PIP_CMD=".venv/Scripts/pip.exe"

  # Install base requirements
  $PIP_CMD install -r requirements.txt 2>/dev/null || true

  if [[ "$rag" == "cloud" ]]; then
    echo "Installing RAG Cloud dependencies..."
    $PIP_CMD install -r ai/config/requirements-rag-cloud.txt
  elif [[ "$rag" == "local" ]]; then
    echo "Installing RAG Local dependencies..."
    $PIP_CMD install -r ai/config/requirements-rag-local.txt
  fi
else
  echo "Warning: Python not found or invalid (Microsoft Store stub?). Skipping venv setup."
fi

echo ""
echo "Project bootstrapped (V2.4)."
echo "  Name:  $project_name"
echo "  Brain: $brain_path"
echo "  RAG:   $rag"
echo "  Env:   .env created"
