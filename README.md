# AgentRealm

Universal template for **projects, seminars, and research** with a seamless Human + AI-Agent workflow. Built around a **"Clean Root"** philosophy: your work is front and center, all automation is tucked away.

---

## Clean Root Philosophy

Your repository root shows only what matters: **your code, your data, your documents.**

| Directory | Purpose | Visibility |
|-----------|---------|------------|
| `src/` | Your project code, homework, assignments | **Your work** |
| `docs/` | Academic writing, seminars, LaTeX, thesis | **Your work** |
| `data/` | All datasets, split into RAG knowledge and project data | **Your work** |
| `ai/` | The "Engine Room" — all automation, RAG, scripts, agent sandboxes | Infrastructure |

### Data Separation

```
data/
├── rag/                  # LLM Knowledge Base (Read-Only)
│   ├── sources/          # Original PDFs, textbooks, lecture slides
│   ├── parsed/           # Clean Markdown extracted by ingestion pipeline
│   └── vector_store/     # ChromaDB vector database (auto-generated)
│
└── process/              # Project Working Data (Read-Write)
    ├── raw/              # Raw measurements, images, survey datasets
    ├── intermediate/     # Data being cleaned or processed
    └── output/           # Final charts, reports, CSV/JSON results
```

> **Rule**: RAG data is **Read-Only** reference material for the LLM. Process data is **Read-Write** operational data for your specific project.

---

## Quick Start

### 1. Initialize & Install

Clone this template and run the bootstrap script:

| OS          | Command                                                                                            |
| :---------- | :------------------------------------------------------------------------------------------------- |
| **Windows** | `.\ai\scripts\helpers\bootstrap-project.ps1 -name "My Project" -ide "vscode" -rag none`            |
| **Linux**   | `./ai/scripts/helpers/bootstrap-project.sh --name "My Project" --ide "antigravity" --rag none`      |

### 2. Configure GitHub (Optional)

If you are logged into the `gh` CLI, the script will automatically apply branch protection rules from `ai/config/github/ruleset.json`.

---

## Human + Agent Workflow

AgentRealm uses **Git Worktrees** to create sandboxes (`ai/worktrees/`) for every task.

### Step 1: Start a Task

```powershell
.\ai\scripts\git\new-task-worktree.ps1 my-task-slug
```

### Step 2: Delegate to Agent

```powershell
.\ai\scripts\agents\run_gemini_task.ps1 ai\worktrees\my-task-slug
```

### Step 3: Sanity Check & Merge

```powershell
.\ai\scripts\helpers\check-all.ps1
.\ai\scripts\git\cleanup-worktrees.ps1 ai\worktrees\my-task-slug
```

---

## RAG Modes

RAG is **opt-in**. By default, no AI/ML packages are installed (zero overhead).

| Mode | Flag | `.venv` Size | Embedding Provider | Offline? |
|------|------|-------------|-------------------|----------|
| **none** | `-rag none` (default) | ~0 MB | — | ✅ |
| **cloud** | `-rag cloud` | ~200 MB | Gemini API | ❌ |
| **local** | `-rag local` | ~1.2 GB | sentence-transformers | ✅ |

### Enable RAG

```powershell
# Cloud mode (lightweight, needs GOOGLE_API_KEY)
.\ai\scripts\helpers\bootstrap-project.ps1 -name "My Project" -rag cloud

# Local mode (heavy, works offline)
.\ai\scripts\helpers\bootstrap-project.ps1 -name "My Project" -rag local
```

### Global Brain (Cross-Project Knowledge)

You can link a shared repository (e.g., `AgentBrain`) to keep skills and lessons learned synchronized across all your projects:

```powershell
.\ai\scripts\helpers\bootstrap-project.ps1 -name "My Project" -brain "git@github.com:user/AgentBrain.git"
```

The bootstrap script will clone it into `ai/knowledge/global/`, and the RAG pipeline will automatically index it.

### Cloud Mode Setup (Gemini API)

1. Get a free API key from [Google AI Studio](https://aistudio.google.com/apikey)
2. Set the key in your environment:

```powershell
# Option A: Set in current session
$env:GOOGLE_API_KEY = "your-api-key-here"

# Option B: Add to .env file (recommended, persists across sessions)
echo 'GOOGLE_API_KEY=your-api-key-here' >> .env
```

```bash
# Linux/macOS
export GOOGLE_API_KEY="your-api-key-here"
# or add to .env
echo 'GOOGLE_API_KEY=your-api-key-here' >> .env
```

> **Note**: The `.env` file is gitignored by default — your key stays private. The Gemini free tier is permanent with generous rate limits, no credit card required.

### Ingest & Chat

Place your PDFs, textbooks, or lecture slides into `data/rag/sources/`, then:

```powershell
python ai/ingestion/doc_parser.py          # Parse & build vector store
.\ai\scripts\agents\start-rag-chat.ps1     # Interactive CRAG chat
```

The CRAG pipeline will: **Retrieve** from your local knowledge base → **Grade** relevance → **Web Search** (if local docs are insufficient) → **Generate** an answer via Gemini.

---

## LaTeX & Seminar Writing

- **Engine**: MiKTeX (Windows) or TeX Live (Linux).
- **Auto-Build**: PDF generates automatically on save.
- **SyncTeX**: Double-click PDF to jump to code; `Ctrl+Alt+J` to jump to PDF.
- **Standards**: Full justification without manual hyphenation.

---

## Governance

- `ai/config/AGENTS.md` — Mandatory rules for all human and AI agents.
- `STATE.md` — The "Live Brain" containing the project backlog and current focus.
