# Agent Task: Brain Evolution

## Goal
Implement components that help the AgentRealm "Brain" evolve dynamically over time: Auto-Discovery of skills and a DeepEval metrics dashboard.

## Requirements

1. **Auto-Discovery (`.ai/scripts/agents/auto-discovery.ps1`)**
   - Write a script that scans completed task worktrees (e.g., reads their `walkthrough.md` or git history).
   - Use an LLM to extract newly learned skills or workflow improvements and append them to `.ai/brain/skills/`.
   - Update `sync-brain.ps1` if necessary to pull these new skills globally.

2. **DeepEval Dashboard (`src/dashboard/app.py`)**
   - Scaffold a local web dashboard (e.g. using Streamlit or Gradio).
   - Connect it to DeepEval or LangSmith to visualize RAG performance metrics (context precision, answer relevancy, etc.).

## Instructions
Review the scaffolding files provided and complete their implementation. Commit your changes to this worktree (`task/brain-evolution`) and test before completion.
