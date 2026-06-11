# AGENTS.md

Global operating rules for humans and AI agents in this repository.

## Roles

- **Planner**: decomposes goals into tasks and updates `STATE.md` backlog. (Default: `copilot-cli`)
- **Researcher**: collects and summarizes sources in `data/rag/sources/`.
- **Coder**: implements code in `src/` and analysis scripts. (Default: `copilot-cli`)
- **Analyst**: transforms data from `data/process/raw` to `data/process/output`.
- **Writer**: produces seminar/thesis text in `docs/`. (Default: `copilot-cli`)
- **Reviewer (QA)**: acts as a strict gatekeeper. Checks for edge cases, security flaws, and syntax errors. Must approve all PRs.

## Non-negotiable rules

1. Never commit directly to `main`.
2. One task = one branch + one worktree.
3. Keep commits scoped and descriptive.
4. Preserve source-of-truth data: never edit files in `data/process/raw/`.
5. Cite sources in `data/rag/sources/` whenever claims are added to seminar text.
6. Reviewer must only use task brief + diff + standards; no implementer chat history.
7. **Global Guidelines**: Always read and follow `.ai/skills/prompts/global.md`.
8. **RAG data is immutable**: Never write generated code, outputs, or operational data into `data/rag/`. That directory is exclusively for reference literature and the vector store.
9. **Git Guardrails**: All agents must respect the pre-commit and pre-push hooks installed via `.ai/scripts/git/setup-guardrails.ps1`. Force-pushing or resetting hard is strictly prohibited for AI agents.
10. **QA Mandate**: No task is considered 'Done' until the Reviewer (QA) agent has verified the implementation against the `qa_reviewer_agent.md` standard.

## Skill Evolution & Knowledge Capture (SSOT Architecture)

To improve workspace efficiency over time, agents must follow these rules:

1. **Global Brain SSOT**: This project connects to a Global AgentBrain (`~/.agentbrain`). This is the **Single Source of Truth** for all reusable skills and architectural guidelines.
2. **Skill Discovery**: If a task requires a complex automation script or a specific prompt sequence that could be reused, the Coder/Planner agent should formalize it as a "Skill" file (using `_TEMPLATE.md`).
3. **Save Location**:
   - If the skill is specific ONLY to this project, save it in `.ai/skills/local/`.
   - If the skill is beneficial for ALL projects (e.g., a generic CSV parser, a LaTeX build optimization), save it directly into the `GLOBAL_BRAIN_PATH`.
4. **Research First**: When facing a complex engineering problem, check the RAG vector store first. Chunks tagged with `source_type: global_skill` contain shared wisdom from the AgentBrain.
5. **Lessons Learned**: Record project-specific "lessons" in `.ai/knowledge/lessons/`. If a lesson applies globally, move it to the Global Brain.
6. **Continuous Improvement**: Propose improvements to existing scripts in `.ai/scripts/` if bugs or inefficiencies are found.

## Directory Philosophy ("Clean Root")

| Directory | Purpose | Who writes here |
|-----------|---------|-----------------|
| `src/` | User's project code, homework, assignments | User & Coder agent |
| `docs/` | Academic writing, seminars, LaTeX, thesis | User & Writer agent |
| `data/rag/` | Immutable reference material for the LLM | Researcher (read-only after ingestion) |
| `data/process/` | Mutable project data (raw inputs → outputs) | Analyst agent |
| `.ai/` | All automation, scripts, RAG, agent worktrees | Infrastructure only |

## Branch and worktree naming

- Branches:
  - `task/<slug>`
  - `review/<task-slug>-<agent>`
  - `docs/<slug>`
  - `fix/<slug>`
- Worktrees:
  - `.ai/worktrees/<slug>`

## Expected task flow

1. Create task worktree with `.ai/scripts/git/new-task-worktree.[sh|ps1]`.
2. Execute work in the worktree.
3. Run quality checks relevant to profile.
4. Create review report in `reviews/code/` or `reviews/text/`.
5. Open PR and merge after review.
6. Remove worktree with `.ai/scripts/git/cleanup-worktrees.[sh|ps1]`.
