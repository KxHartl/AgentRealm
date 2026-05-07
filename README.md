# 🌌 AgentRealm

Universal template for **projects, seminars, and research** with a seamless Human + AI-Agent workflow. Built for speed, isolation, and cross-platform compatibility.

---

## ✨ Key Features

- 🚀 **One-Command Setup**: Bootstrap your project and install all dependencies automatically.
- 🛡️ **Safe Sandboxing**: Use Git Worktrees to isolate agent tasks and prevent code contamination.
- 💻 **Cross-Platform**: Full support for **Windows (PowerShell)** and **Linux (Bash)**.
- 🤖 **Agent Ready**: Pre-configured for Claude, Gemini, Copilot, and custom agents.
- 📝 **Seminar Optimized**: Professional LaTeX environment with auto-build and SyncTeX support.

---

## 📋 Prerequisites

Before you start, ensure you have a package manager installed:

- **Windows**: [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (Default on Win 10/11).
- **macOS/Linux**: [Homebrew](https://brew.sh/) or a system package manager (apt/dnf).

---

## 🚀 Quick Start

### 1. Initialize & Install

Clone this template and run the bootstrap script. It will automatically detect missing programs (Git, Python, Node, Pandoc, MiKTeX) and offer to install them.

| OS          | Command                                                                          |
| :---------- | :------------------------------------------------------------------------------- |
| **Windows** | `.\scripts\helpers\bootstrap-project.ps1 -name "My Project" -ide "vscode"`       |
| **Linux**   | `./scripts/helpers/bootstrap-project.sh --name "My Project" --ide "antigravity"` |

#### ⚙️ Bootstrap Options

| Parameter          | Values                  | Description                                              |
| :----------------- | :---------------------- | :------------------------------------------------------- |
| `-name` / `--name` | `string`                | Name of your project (updates configs and STATE.md).     |
| `-ide` / `--ide`   | `vscode`, `antigravity` | Selects your default workspace tool (default: `vscode`). |

### 2. Configure GitHub (Optional)

If you are logged into the `gh` CLI, the script will automatically apply branch protection rules from `config/github/ruleset.json`.

---

## 🛠️ Human + Agent Workflow

AgentRealm uses **Git Worktrees** to create "Sandboxes" (`.agents/`) for every task. This keeps your main workspace clean while agents work.

### Step 1: Start a Task

Create a new sandbox for a specific goal. This creates a branch and opens a dedicated folder.

- `.\scripts\git\new-task-worktree.ps1 my-task-slug`

### Step 2: Delegate to Agent

Run your agent inside the sandbox. The agent will have access to the full repository context but its changes remain isolated.

- `.\scripts\agents\run_gemini_task.ps1 .agents\my-task-slug`

### Step 3: Sanity Check & Merge

Before merging, run the automated quality checks:

- `.\scripts\helpers\check-all.ps1`
  Then commit your changes and cleanup the worktree:
- `.\scripts\git\cleanup-worktrees.ps1 .agents\my-task-slug`

---

## 📝 LaTeX & Seminar Writing

This template is optimized for high-quality academic writing.

### 🔧 Setup

- **Engine**: [MiKTeX](https://miktex.org/) (Windows) or TeX Live (Linux).
- **VS Code Extension**: [LaTeX Workshop](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop).
- **Features**:
  - **Auto-Build**: PDF generates automatically on save.
  - **SyncTeX**: Double-click PDF to jump to code; `Ctrl+Alt+J` to jump to PDF.
  - **Clean Root**: All build artifacts go to the `build/` folder.

### 📐 Standards

Per `skills/prompts/global.md`, all LaTeX documents should use:

- **Full justification** (`\sloppy` or `\fussy` as appropriate).
- **No manual hyphenation** (let the engine handle it).

---

## 📁 Repository Structure

- `docs/` - Seminars, thesis, and references.
- `src/` - Core implementation code.
- `analysis/` - Data analysis, Python notebooks, and processed results.
- `data/` - Datasets (keep `raw/` immutable!).
- `scripts/` - Universal automation helpers.
- `config/` - Project and environment specifications.

---

## 🤖 Governance

- `AGENTS.md` - Mandatory rules for all human and AI agents.
- `STATE.md` - The "Live Brain" containing the project backlog and current focus.
