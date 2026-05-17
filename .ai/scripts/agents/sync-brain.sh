#!/usr/bin/env bash
# Sync AgentBrain Skills and Update Local RAG
# Usage: ./.ai/scripts/agents/sync-brain.sh

# 1. Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

BRAIN_PATH_RAW=${GLOBAL_BRAIN_PATH:-"~/.agentbrain"}
BRAIN_PATH="${BRAIN_PATH_RAW/#\~/$HOME}"

echo "--- Syncing Global AgentBrain ---"
echo "Target: $BRAIN_PATH"

if [ -d "$BRAIN_PATH" ]; then
  if [ -d "$BRAIN_PATH/.git" ]; then
    echo "Fetching latest skills from origin..."
    cd "$BRAIN_PATH" && git pull origin main && cd - > /dev/null
  else
    echo "Brain is not a git repository. Skipping pull."
  fi
  
  echo "Updating local RAG vector store..."
  PY_CMD="python"
  if [[ -f ".venv/bin/python" ]]; then
    PY_CMD=".venv/bin/python"
  elif [[ -f ".venv/Scripts/python.exe" ]]; then
    PY_CMD=".venv/Scripts/python.exe"
  elif command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
    PY_CMD="python3"
  fi
  
  $PY_CMD .ai/ingestion/doc_parser.py || echo "Warning: RAG ingestion failed. Python might be missing or invalid."
  
  echo "--- Sync Complete ---"
else
  echo "Error: Global Brain not found at $BRAIN_PATH"
  exit 1
fi
