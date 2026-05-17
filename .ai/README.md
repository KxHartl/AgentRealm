# .ai/ — The Engine Room

**All automation, AI infrastructure, and agent tooling lives here.** This directory is hidden from your day-to-day work but powers everything behind the scenes.

## Structure

| Subdirectory | Purpose |
|---|---|
| `config/` | Project configuration, GitHub rules, IDE settings |
| `scripts/` | PowerShell and Bash automation (bootstrap, checks, agent launchers) |
| `skills/` | Agent prompts, local skill scripts, registry |
| `worktrees/` | Git Worktree sandboxes for isolated agent tasks |
| `rag_core/` | Corrective RAG (CRAG) pipeline built with LangGraph |
| `ingestion/` | Document parsing and vector store builder |

## Key Commands (run from repository root)

```powershell
# Bootstrap a new project
.\.ai\scripts\helpers\bootstrap-project.ps1 -name "My Project"

# Create a task sandbox
.\.ai\scripts\git\new-task-worktree.ps1 my-task

# Run sanity checks
.\.ai\scripts\helpers\check-all.ps1

# Ingest documents into RAG
python .ai/ingestion/doc_parser.py

# Start RAG chat
.\.ai\scripts\agents\start-rag-chat.ps1
```

> **Rule**: Users should not need to look inside this directory during normal work. Everything is accessible via scripts from the repository root.
