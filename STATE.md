# STATE.md

## Project info

- Name: _TBD_
- Type: _TBD_
- Owner: _TBD_

## Requirements

- Manifest: `ai/config/requirements.list`
- Check command: `ai/scripts/helpers/check-requirements.[ps1|sh]`
- Worktree Root: `d:\projects\AgentRealm\ai\worktrees\rag-improvements`
- Installation status: _Not checked yet._

## Current focus
- v3-enterprise-hardening

- **AgentRealm V3.0**: Enterprise Guardrails, Advanced RAG (Fusion/Rerank), and Evaluation Pipeline.

## Backlog

- [ ] Test RAG Evaluation Pipeline with real-world scenarios.
- [ ] Implement automated Cross-Encoder setup in bootstrap.
- [ ] Refine QA Reviewer agent prompts for specific languages.
- [ ] Test CRAG pipeline end-to-end with sample documents.

## Changelog

- 2026-05-14: **V3.0 Bootstrap Hardening** — Robust Python detection, support for `-brain` parameter, and improved requirements check for Windows/Linux.
- 2026-05-14: **Documentation Overhaul** — Complete rewrite of README.md and creation of detailed instructions.md for improved onboarding and workflow clarity.
- 2026-05-11: **V2 Refactor** — Clean Root architecture, CRAG pipeline, data/rag + data/process separation.
- 2026-05-07: Standardized PR workflow with a new GitHub PR template.
- 2026-05-07: Added automated Python Virtual Environment setup to bootstrap script.
- 2026-05-07: Created unified documentation build system (`build-docs.ps1/sh`).
- 2026-05-07: Optimized LaTeX Workshop settings for VS Code.
