# AgentRealm

Universal template for **projects, seminars, and research** with a seamless Human + AI-Agent workflow. Built around a **"Clean Root"** philosophy: your work is front and center, all automation is tucked away.

---

## 🚀 Bootstrap New Project

The quickest way to get started is using the automated bootstrap scripts. This handles virtual environments, requirement installations, RAG configurations, and linking external knowledge like AgentBrain.

### Recommended Default Commands

| OS | Command |
| :--- | :--- |
| **Windows** | `.\ai\scripts\helpers\bootstrap-project.ps1 -name "My Project" -ide antigravity -rag cloud -brain "C:\Users\KHartl\.agentbrain"` |
| **Linux/Mac** | `./ai/scripts/helpers/bootstrap-project.sh --name "My Project" --ide antigravity --rag cloud --brain "~/.agentbrain"` |

### All Bootstrap Flags & Options

When running the `bootstrap-project` script, customize your configuration with these flags:

- `-name` / `--name` : **(Required)** The title of your new project.
- `-ide` / `--ide` : IDE setup to use. Recommended: `antigravity` (default), `vscode`.
- `-rag` / `--rag` : Choose your AI embedding/RAG strategy:
  - `none`: Minimal setup, ~0MB `.venv`, fully offline (default).
  - `cloud`: Uses Gemini API for generation and embeddings (~200MB `.venv`). Fast, but requires internet and `GOOGLE_API_KEY`.
  - `local`: Uses local models like `sentence-transformers` (~1.2GB `.venv`). Fully offline and private, but slow and large.
- `-brain` / `--brain` : Path to a global skills repository (e.g., `AgentBrain`) to link cross-project learnings. Can be a local path or Git URL.

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

### Global Brain (Cross-Project Knowledge)

When you use the `-brain` flag in the bootstrap commands above, the script links your shared `AgentBrain` repository to keep skills and lessons learned synchronized across all your projects.

The bootstrap script clones or links it into `ai/knowledge/global/`, and the RAG pipeline automatically indexes it.

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
