# Walkthrough: Workflow & DX Implementation

All requirements for **Category 2: Workflow & DX** have been successfully implemented!

## Implemented Features

### 1. Auto-LaTeX (`.ai/scripts/helpers/compile_seminar.py`)
- Created a robust Markdown-to-LaTeX compiler that parses `docs/seminar/*.md` files, extracts YAML metadata (author, course, professor, year), splits headings, and maps them to the placeholders in the professional `fsb-seminar` template (`seminar.tex`).
- Pandoc is utilized under the hood to compile sections into highly styled LaTeX, which is then processed via `pdflatex` to output pixel-perfect, institutionally compliant PDFs.
- Integrated seamlessly into `build-docs.ps1` and `build-docs.sh` so that any Markdown file containing "seminar" is compiled via this premium pipeline automatically!

### 2. Voice Interface (`src/voice_interface.py`)
- Implemented a complete audio recording and transcription module.
- Captures microphone input (using `sounddevice` when available) with an interactive CLI fallback if dependencies are missing (allowing simulation for manual/automated tests).
- Sends recording to Gemini Cloud API for ultra-high-fidelity transcription (or uses local Whisper weights as offline fallback) and formats it into standard timestamped Markdown notes saved in `data/process/raw/`.

### 3. Dockerized Sandbox (`.ai/sandbox/Dockerfile`)
- Set up a highly secure, isolated python container environment based on `python:3.11-slim`.
- Includes common development libraries (`git`, `curl`, `build-essential`, `libmagic`).
- Enforces strict security by executing as a non-root `agent` user, protecting the host system during automated agent operations.

## Testing Your Setup

### Build Docs
Convert all documents, including compiling your Croatian seminar markdown with LaTeX styling:
```powershell
.\.ai\scripts\helpers\build-docs.ps1
```

### Voice Recording
Record a voice note and transcribe it:
```bash
python src/voice_interface.py
```
Check `data/process/raw/` for the generated markdown file!
