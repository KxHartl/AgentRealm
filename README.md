# AgentRealm

> Project template for work with AI agents: a clean root for your own work, and all automation,
> RAG and agent sandboxes kept in one `.ai/` engine room.

![Status](https://img.shields.io/badge/status-superseded%20by%20WorkRealm-lightgrey)
![Template](https://img.shields.io/badge/GitHub-template-6f42c1)
[![Works with](https://img.shields.io/badge/brain-AgentBrain-6f42c1)](https://github.com/KxHartl/AgentBrain)

---

## Status

AgentRealm is the **first generation** (April to June 2026) of a toolchain for working with AI
agents. It is kept as a template and for reference. New work uses its successors:

| Project | What it is |
| --- | --- |
| [LiteRealm](https://github.com/KxHartl/LiteRealm) | Second generation: template for academic LaTeX work, seminars and theses |
| [WorkRealm](https://github.com/KxHartl/WorkRealm) | Current generation: workspace generator with Git-enforced rules for every tool |
| [AgentBrain](https://github.com/KxHartl/AgentBrain) | The shared brain: agents, skills, templates and RAG scripts |

---

## The "clean root" idea

AgentRealm keeps your work in focus. The automation, RAG systems and agent sandboxes are hidden
in the `.ai/` folder, while the root of the repository stays clean and readable.

| Folder | Purpose | Focus |
| :----- | :------ | :---- |
| `src/` | Main project code, algorithms and scripts | Your work |
| `docs/` | Documentation, seminars, LaTeX and reports | Your work |
| `data/` | Data, split into RAG sources and project data | Your work |
| `.ai/` | The "engine room": scripts, agents and infrastructure | Infrastructure |

## Starting a new project

One command sets up the virtual environment, installs the dependencies and connects the project
to your shared knowledge.

### Options

| Parameter | Description | Values | Default | Note |
| :-------- | :---------- | :----- | :------ | :--- |
| **`-name`** | Project identity | `Text` | *(required)* | Updates `project.yaml` and `STATE.md` |
| **`-brain`** | Shared knowledge mode | `none`, `global`, `local` | `global` | Connects the shared skills and lessons |
| **`-rag`** | Retrieval mode | `none`, `cloud`, `local` | `none` | Decides the dependencies and ML models |
| **`-ide`** | Editor configuration | `vscode`, `antigravity` | `vscode` | Sets up `.vscode` and the agent sandboxes |

### RAG modes

| Mode | Footprint | Needs | Advantages |
| :--- | :-------- | :---- | :--------- |
| **`none`** | ~0 MB | — | Fast, no ML dependencies |
| **`cloud`** | ~200 MB | `GOOGLE_API_KEY` | Light, uses the Gemini API (online) |
| **`local`** | ~1.2 GB | GPU (optional) | Private, works fully offline |

### Examples

**Windows (PowerShell):**

```powershell
.\.ai\scripts\helpers\bootstrap-project.ps1 -name "My_Project" -brain global -rag cloud
```

Default shared path: `~/.agentbrain` (Windows) / `~/.agentrealm` (Linux)

**Linux / macOS (Bash):**

```bash
./.ai/scripts/helpers/bootstrap-project.sh --name "My_Project" --brain global --rag cloud
```

Default shared path: `~/.agentrealm`

### Brain modes

- **`none`**: the project is isolated and uses no shared knowledge.
- **`global`**: uses the shared folder in your home directory. If it does not exist, AgentRealm
  tries to clone the **AgentBrain** repository there.
- **`local`**: the brain is created inside the project (`.ai/brain/`). Useful for specific
  research projects.

---

## Workflow: human and agent

AgentRealm uses **Git worktrees** to isolate every task. The agent never works directly on your
`main` branch.

1. **Start a task:** create a sandbox for it.
   ```powershell
   .\.ai\scripts\git\new-task-worktree.ps1 "implement-feature-x"
   ```
2. **Delegate:** send the agent to work in it.
   ```powershell
   .\.ai\scripts\agents\run_claude_task.ps1 .ai\worktrees\implement-feature-x
   ```
3. **Review and merge:** check the result and merge it into the project.
   ```powershell
   .\.ai\scripts\helpers\check-all.ps1
   .\.ai\scripts\git\cleanup-worktrees.ps1 .ai\worktrees\implement-feature-x
   ```

---

## RAG and shared knowledge

- **Global brain:** a shared repository (`~/.agentbrain`) that keeps your skills and lessons
  learned across all projects.
- **CRAG pipeline:** the agent searches your local literature first (`data/rag/sources`), then the
  global brain, and the web only when needed.

**Cloud RAG (Gemini):** get a key at [Google AI Studio](https://aistudio.google.com/apikey) and
add `GOOGLE_API_KEY=your_key` to `.env`.

## Academic LaTeX templates

AgentRealm ships with templates for the **Faculty of Mechanical Engineering and Naval
Architecture (FSB)**, University of Zagreb: seminar, thesis and paper. The build is automatic,
with SyncTeX support and the faculty's formatting already set. See [`docs/`](docs/).

## Governance and safety

- **`STATE.md`**: the project's live memory, so you always know what comes next.
- **`AGENTS.md`**: strict rules of behaviour for AI agents.
- **Git guardrails**: protection against commits to the wrong branch and leaked API keys.
