# Agent Task: Workflow & DX

## Goal
Implement Developer Experience (DX) upgrades and workflow automations, including Auto-LaTeX compilation, Voice Interface, and a Dockerized Sandbox for agents.

## Requirements

1. **Auto-LaTeX (`.ai/scripts/helpers/build-docs.ps1`)**
   - Enhance the Pandoc conversion logic to automatically apply the FSB LaTeX templates located in `.ai/templates/fsb-seminar` when converting `docs/seminar/*.md` files to PDF.
   
2. **Voice Interface (`src/voice_interface.py`)**
   - Implement a script that captures audio from the microphone and uses a Speech-to-Text model (like Whisper) to generate text notes.
   - Save these raw notes into `data/process/raw/`.

3. **Dockerized Sandbox (`.ai/sandbox/Dockerfile`)**
   - Create a Dockerfile that sets up an isolated environment for agents to run unsafe code or execute complex processes.

## Instructions
Review the scaffolding files provided and complete their implementation. Commit your changes to this worktree (`task/workflow-dx`) and test before completion.
