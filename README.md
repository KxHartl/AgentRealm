# 🌌 AgentRealm

Universal template for **projects, seminars, and research** with a seamless Human + AI-Agent workflow. Built for speed, isolation, and cross-platform compatibility.

---

## ✨ Key Features
- 🚀 **One-Command Setup**: Bootstrap your project in seconds.
- 🛡️ **Safe Sandboxing**: Use Git Worktrees to isolate agent tasks.
- 💻 **Cross-Platform**: Full support for **Windows (PowerShell)** and **Linux (Bash)**.
- 🤖 **Agent Ready**: Pre-configured for Claude, Gemini, Copilot, and more.
- 📝 **Seminar Optimized**: Professional LaTeX templates with auto-justification.

---

## 🚀 Quick Start

### 1. Initialize Project
Go to the [AgentRealm](https://github.com/your-username/agentRealm) repo and click **"Use this template"**. Clone your new repo and run:

| OS | Command |
| :--- | :--- |
| **Windows** | `.\scripts\helpers\bootstrap-project.ps1 -name "My Project" -ide vscode` |
| **Linux** | `./scripts/helpers/bootstrap-project.sh --name "My Project" --ide vscode` |

#### ⚙️ Bootstrap Options
| Parameter | Values | Description |
| :--- | :--- | :--- |
| `-name` | `string` | Name of your project (updates configs and STATE.md). |
| `-ide` | `vscode`, `antigravity` | Selects your default workspace tool (CLI or GUI). |

---

## 🛠️ Daily Workflow

### Step 1: Create a Task Sandbox
Create an isolated environment for your current task. This will automatically open your IDE and a new terminal.

- **Windows**: `.\scripts\git\new-task-worktree.ps1 my-task-slug`
- **Linux**: `./scripts/git/new-task-worktree.sh my-task-slug`

### Step 2: Run an AI Agent
Launch your preferred agent inside the sandbox.

- **Windows**: `.\scripts\agents\run_claude_task.ps1 .agents\my-task-slug`
- **Linux**: `./scripts/agents/run_claude_task.sh .agents/my-task-slug`

### Step 3: Review & Merge
Once the task is done, review the changes, commit, and cleanup.

```powershell
# Cleanup sandbox
# Windows
.\scripts\git\cleanup-worktrees.ps1 .agents\my-task-slug

# Linux
./scripts/git/cleanup-worktrees.sh .agents/my-task-slug
```

---

## 🛡️ The Golden Rules
1. **1 Task = 1 Worktree**: Never cross-contaminate tasks.
2. **Never Commit to `main`**: Always work in branches.
3. **Review Everything**: Use `git diff` before merging agent work.

---

## 📁 Structure
- `docs/` - Seminars, thesis, and references.
- `src/` - Implementation code.
- `analysis/` - Data notebooks and reports.
- `data/` - Raw and processed datasets.
- `scripts/` - Universal automation tools.
- `.agents/` - Temporary task sandboxes (ignored by git).

---

## 🤖 Global State
- `AGENTS.md` - The Rulebook for AI agents.
- `STATE.md` - The Live Brain (backlog and focus).
