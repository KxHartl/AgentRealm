# Global Agent Guidelines

These rules apply to all AI agents working in this repository.

## Communication
- **Primary Language**: Use **Croatian** for chat interactions and explanations.
- **Technical Language**: Use **English** for code, commit messages, and PR descriptions.
- **Tone**: Professional, concise, and technical.

## Code Standards
- **Naming**: Use camelCase for variables/functions, PascalCase for classes.
- **Style**: Follow standard PEP8 for Python and Google C++ Style Guide for C++.
- **Comments**: Write concise English docstrings for all public methods.

## Git Workflow
- **Isolation**: Always work in a dedicated worktree (`.ai/worktrees/<slug>`).
- **State**: Keep `STATE.md` updated with your progress.
- **Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat:`, `fix:`, `docs:`).

## Document Formatting
- **Markdown**: Use GitHub Flavored Markdown.
- **Tables**: Ensure tables are properly aligned.
- **Justification**: In LaTeX documents, ensure full justification without manual hyphenation.

## Sanity Checks
- Run `.\.ai\scripts\helpers\check-all.ps1` (or `.sh`) before finalizing any task.
- Ensure all requirements are met using `check-requirements`.

## Data Rules
- **RAG data** (`data/rag/`): Read-Only. NEVER write generated code or outputs here.
- **Process data** (`data/process/raw/`): Read raw inputs from here.
- **Process outputs** (`data/process/output/`): Write computational results here.
