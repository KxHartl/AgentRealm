#!/usr/bin/env bash
# Sync AgentBrain Skills and Update Local RAG
# Usage: ./ai/scripts/agents/sync-brain.sh

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
  if [ -f ".venv/bin/python" ]; then
    .venv/bin/python ai/ingestion/doc_parser.py
  else
    python3 ai/ingestion/doc_parser.py
  fi
  
  echo "--- Sync Complete ---"
else
  echo "Error: Global Brain not found at $BRAIN_PATH"
  exit 1
fi
