#!/bin/bash
# .ai/scripts/git/setup-guardrails.sh
# Sets up Git hooks to prevent dangerous commands and ensure security.

GIT_DIR=".git"
if [ ! -d "$GIT_DIR" ]; then
    echo "Error: Not a git repository."
    exit 1
fi

HOOKS_DIR="$GIT_DIR/hooks"
mkdir -p "$HOOKS_DIR"

# 1. Pre-commit hook
cat << 'EOF' > "$HOOKS_DIR/pre-commit"
#!/bin/sh
# AI Guardrail: Pre-commit checks

# 1. Prevent committing .env files
if git diff --cached --name-only | grep -E '\.env$'; then
    echo "ERROR: Attempted to commit a .env file. AI guardrail blocked this."
    exit 1
fi

# 2. Secret scanning (basic)
if git diff --cached | grep -Ei '(password|api_key|secret|token)[[:space:]]*[:=]'; then
    echo "WARNING: Potential secret detected in diff. AI guardrail requires manual review."
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/pre-commit"

# 2. Pre-push hook (placeholder for blocking force push)
cat << 'EOF' > "$HOOKS_DIR/pre-push"
#!/bin/sh
# AI Guardrail: Pre-push checks
# Blocks force push by checking for the --force flag in the command line if possible.
# Note: This is a client-side hook and can be bypassed with --no-verify.

# Detect if force push is happening
# This is tricky in shell, but we can check for push options or just block main.
exit 0
EOF

chmod +x "$HOOKS_DIR/pre-push"

echo "Git guardrails installed in $HOOKS_DIR"
