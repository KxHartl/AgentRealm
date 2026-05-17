#!/usr/bin/env bash
set -euo pipefail

project_name=""
ide="vscode"
rag="none"
brain_mode="global"
brain_repo="https://github.com/KxHartl/AgentBrain.git"

usage() {
  echo "Usage: $0 --name <project-name> [--ide <vscode|antigravity>] [--rag <none|cloud|local>] [--brain <none|global|local>] [--brain-repo <url>]"
  echo ""
  echo "Options:"
  echo "  --name        Project name (required)."
  echo "  --ide         IDE to use (vscode|antigravity). Default: vscode."
  echo "  --rag         RAG mode (none|cloud|local). Default: none."
  echo "  --brain       Brain mode (none|global|local). Default: global."
  echo "  --brain-repo  Source URL for AgentBrain clone. Default: KxHartl/AgentBrain."
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
      brain_mode="$2"
      shift 2
      ;;
    --brain-repo)
      brain_repo="$2"
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
sed -i "s/^name: .*/name: \"${project_name}\"/" .ai/config/project.yaml
sed -i "s/^default_ide: .*/default_ide: \"${ide}\" # vscode | antigravity/" .ai/config/project.yaml
sed -i "s/^rag_mode: .*/rag_mode: \"${rag}\" # none | cloud | local/" .ai/config/project.yaml
sed -i "s/^brain_mode: .*/brain_mode: \"${brain_mode}\" # none | global | local/" .ai/config/project.yaml

curr_date=$(date +%Y-%m-%d)
cat <<EOF > STATE.md
# STATE.md

## Project info

- Name: ${project_name}
- Type: seminar
- Owner: $(whoami)

## Requirements

- Manifest: .ai/config/requirements.list
- Check command: .ai/scripts/helpers/check-requirements.sh
- Installation status: _Not checked yet._

## Current focus
- project-init

- **AgentRealm V3.0**: Integrated Global AgentBrain ($brain_mode mode).

## Backlog

- [ ] Add project source files to src/
- [ ] Add research documents to data/rag/sources/
- [ ] Sync Global Brain skills: ./.ai/scripts/agents/sync-brain.sh

## Changelog

- ${curr_date}: **Project Initialized** — V3.0 Architecture with $brain_mode AgentBrain.
EOF

# 2. Setup .env from .env.example
if [[ ! -f .env ]]; then
  echo "Creating .env from .env.example..."
  cp .env.example .env
fi

# 3. Resolve and Verify Brain
brain_path=""
if [[ "$brain_mode" == "global" ]]; then
  # V3.0 Standard: .agentrealm for global brain
  brain_path="${HOME}/.agentrealm"
  # Special check for user's specific Windows path if in MINGW
  if [[ -d "/c/Users/KHartl/.agentrealm" ]]; then
    brain_path="/c/Users/KHartl/.agentrealm"
  fi

  if [[ ! -d "$brain_path" ]]; then
    echo "Global AgentBrain not found at ${brain_path}. Attempting to clone from ${brain_repo}..."
    git clone "$brain_repo" "$brain_path" || {
      echo "Warning: Failed to clone AgentBrain. Creating empty directory."
      mkdir -p "$brain_path"
    }
  fi
elif [[ "$brain_mode" == "local" ]]; then
  brain_path="$(pwd)/.ai/brain"
  mkdir -p "$brain_path"
fi

if [[ "$brain_mode" != "none" ]]; then
  echo "Connecting to AgentBrain ($brain_mode) at ${brain_path}..."
  
  # Update .env
  if [[ -f .env ]]; then
    if grep -q "GLOBAL_BRAIN_PATH=" .env; then
      sed -i "s|GLOBAL_BRAIN_PATH=.*|GLOBAL_BRAIN_PATH=${brain_path}|" .env
    else
      echo "GLOBAL_BRAIN_PATH=${brain_path}" >> .env
    fi
  fi

  if [[ -d "${brain_path}/.git" ]]; then
    echo "Brain is a git repo. Pulling latest skills..."
    cd "$brain_path" && git pull origin main && cd - > /dev/null
  fi
  
  if [[ -f .ai/scripts/agents/sync-brain.sh ]]; then
    echo "Syncing Brain to local cache..."
    bash .ai/scripts/agents/sync-brain.sh
  fi
  echo "AgentBrain connected and cached."
else
  echo "AgentBrain disabled (mode: none)."
fi

# Update README.md
if [[ -f README.md ]]; then
  sed -i "s/^# AgentRealm/# ${project_name}/" README.md
  sed -i "s/Universal template for \*\*projects, seminars, and research\*\*/Project for **${project_name}**, built using AgentRealm template/" README.md
fi

mkdir -p .ai/worktrees

# 4. Check requirements
echo "Verifying project requirements..."
bash ./.ai/scripts/helpers/check-requirements.sh || echo "Warning: Some requirements are missing."

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
    $PIP_CMD install -r .ai/config/requirements-rag-cloud.txt
  elif [[ "$rag" == "local" ]]; then
    echo "Installing RAG Local dependencies..."
    $PIP_CMD install -r .ai/config/requirements-rag-local.txt
  fi
else
  echo "Warning: Python not found or invalid (Microsoft Store stub?). Skipping venv setup."
fi

echo ""
echo "Project bootstrapped (V3.0)."
echo "  Name:  $project_name"
echo "  Brain: $brain_path"
echo "  RAG:   $rag"
echo "  Env:   .env created"
