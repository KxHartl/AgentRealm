# AGENTS.md

Global operating rules for humans and AI agents in this repository.

## Roles

- **Planner**: decomposes goals into tasks and updates `STATE.md` backlog. (Default: `copilot-cli`)
- **Researcher**: collects and summarizes sources in `data/rag/sources/`.
- **Coder**: implements code in `src/` and analysis scripts. (Default: `copilot-cli`)
- **Analyst**: transforms data from `data/process/raw` to `data/process/output`.
- **Writer**: produces seminar/thesis text in `docs/`. (Default: `copilot-cli`)
- **Reviewer**: reviews code/text quality and writes reports into `reviews/`. (Default: `copilot-cli`)

## Non-negotiable rules

1. Never commit directly to `main`.
2. One task = one branch + one worktree.
3. Keep commits scoped and descriptive.
4. Preserve source-of-truth data: never edit files in `data/process/raw/`.
5. Cite sources in `data/rag/sources/` whenever claims are added to seminar text.
6. Reviewer must only use task brief + diff + standards; no implementer chat history.
7. **Global Guidelines**: Always read and follow `ai/skills/prompts/global.md`.
8. **RAG data is immutable**: Never write generated code, outputs, or operational data into `data/rag/`. That directory is exclusively for reference literature and the vector store.

## Directory Philosophy ("Clean Root")

| Directory | Purpose | Who writes here |
|-----------|---------|-----------------|
| `src/` | User's project code, homework, assignments | User & Coder agent |
| `docs/` | Academic writing, seminars, LaTeX, thesis | User & Writer agent |
| `data/rag/` | Immutable reference material for the LLM | Researcher (read-only after ingestion) |
| `data/process/` | Mutable project data (raw inputs → outputs) | Analyst agent |
| `ai/` | All automation, scripts, RAG, agent worktrees | Infrastructure only |

## Branch and worktree naming

- Branches:
  - `task/<slug>`
  - `review/<task-slug>-<agent>`
  - `docs/<slug>`
  - `fix/<slug>`
- Worktrees:
  - `ai/worktrees/<slug>`

## Expected task flow

1. Create task worktree with `ai/scripts/git/new-task-worktree.[sh|ps1]`.
2. Execute work in the worktree.
3. Run quality checks relevant to profile.
4. Create review report in `reviews/code/` or `reviews/text/`.
5. Open PR and merge after review.
6. Remove worktree with `ai/scripts/git/cleanup-worktrees.[sh|ps1]`.
