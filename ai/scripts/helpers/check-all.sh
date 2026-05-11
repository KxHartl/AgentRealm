#!/usr/bin/env bash
# Unified Sanity Check
# Detects project content and runs relevant quality checks.

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [[ ! -f "${root_dir}/STATE.md" ]]; then
  if [[ -f "../../STATE.md" ]]; then
    root_dir="../.."
  fi
fi
cd "$root_dir"

echo "--- Starting Unified Sanity Check ---"

# 1. Python Checks
if find . -maxdepth 3 -name "*.py" | grep -q .; then
  echo "[Python] Files detected. Running ruff..."
  if command -v ruff >/dev/null 2>&1; then
    ruff check .
    ruff format --check .
  else
    echo "Warning: ruff not found. Skipping Python linting."
  fi
fi

# 2. LaTeX Checks
if find . -maxdepth 3 -name "*.tex" | grep -q .; then
  echo "[LaTeX] Files detected. Running chktex..."
  if command -v chktex >/dev/null 2>&1; then
    chktex -q .
  else
    echo "Warning: chktex not found. Skipping LaTeX linting."
  fi
fi

# 3. Node.js Checks
if [[ -f "package.json" ]]; then
  echo "[Node.js] package.json detected. Checking for lint script..."
  if grep -q '"lint":' package.json; then
    npm run lint
  else
    echo "No lint script found in package.json."
  fi
fi

# 4. C++ Checks
if [[ -f "CMakeLists.txt" ]]; then
  echo "[C++] CMakeLists.txt detected."
  echo "Tip: Run 'cmake -S . -B build' and 'cmake --build build' to verify build."
fi

echo "--- Sanity Check Finished ---"
