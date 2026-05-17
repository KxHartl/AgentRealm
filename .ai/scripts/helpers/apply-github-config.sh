#!/usr/bin/env bash
# Apply GitHub Ruleset
# Uses 'gh' CLI to import the ruleset from .ai/config/github/ruleset.json

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ruleset_file="${root_dir}/.ai/config/github/ruleset.json"

if [[ ! -f "$ruleset_file" ]]; then
  # If we are deeper in the tree, try to find root
  if [[ -f "../../../.ai/config/github/ruleset.json" ]]; then
    root_dir="../../.."
    ruleset_file="${root_dir}/.ai/config/github/ruleset.json"
  fi
fi

if [[ ! -f "$ruleset_file" ]]; then
  echo "Ruleset file not found at $ruleset_file"
  echo "Current directory: $(pwd)"
  echo "Try adding this directory to git safe.directory if you are on a network share."
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) not found. Please install it first."
  exit 1
fi

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
if [[ -z "$repo" ]]; then
  echo "Could not determine GitHub repository name."
  exit 1
fi

echo "Applying ruleset to $repo..."

gh api "repos/${repo}/rulesets" --method POST --input "$ruleset_file" --silent

if [[ $? -eq 0 ]]; then
  echo "Successfully applied GitHub ruleset!"
else
  echo "Failed to apply ruleset."
  exit 1
fi
