# agentic-workspace

Universal GitHub template for **projects / seminars / thesis** with shared human + AI-agent workflow.

## What this template provides

- One repository structure for code, data, writing, figures, and reviews.
- Multi-agent safe workflow using **git worktrees** (isolated task sandboxes).
- Standardized operating files: `AGENTS.md` and `STATE.md`.
- Selectable profiles: `python`, `cpp`, `document` (LaTeX-first with optional DOCX export).
- Portable requirement tracing through `config/requirements.list` and `scripts/helpers/check-requirements.sh`.
- Starter scripts for setup, worktree lifecycle, and launching common AI CLIs.

## Quick start

1. Create a new repository with **Use this template**.
2. Clone it and run:
   ```bash
   ./scripts/helpers/bootstrap-project.sh --name "My Project" --profile document
   ```
3. Check machine prerequisites:
   ```bash
   ./scripts/helpers/check-requirements.sh
   ```
4. Create your first task worktree:
   ```bash
   ./scripts/git/new-task-worktree.sh literature-review
   ```
5. Run an agent in that worktree:
   ```bash
   ./scripts/agents/run_copilot_task.sh .agents/literature-review
   ```
6. Commit from the worktree branch, open PR, merge to `main`, then cleanup:
   ```bash
   ./scripts/git/cleanup-worktrees.sh .agents/literature-review
   ```

## Core folders

- `docs/`, `assets/`, `reviews/`: seminar/thesis writing and quality gates.
- `src/`, `analysis/`, `data/`: implementation and data pipeline.
- `config/`, `skills/`, `scripts/`: agent roles, prompts, local skills, automation.
- `.agents/`: local git worktree sandboxes for parallel agent execution.

## Workflow model

- Planner updates backlog in `STATE.md` or GitHub Issues.
- Implementer agents each work in their own worktree branch (`task/*`).
- Reviewer agents evaluate only task context + diff + standards (unbiased flow).
- Merge only reviewed work into `main`.
