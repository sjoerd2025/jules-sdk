#!/usr/bin/env bash
# ==============================================================================
# Universal GitHub Agentic Workflows (gh-aw) Repository Initializer
#
# Configures any Git repository for GitHub Agentic Workflows:
# 1. Verifies gh CLI & gh-aw extension
# 2. Runs gh aw init to set up .gitattributes, dispatcher skills, and editor configs
# 3. Compiles and validates all markdown workflows into .lock.yml files
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

echo "================================================================="
echo "🤖 GitHub Agentic Workflows (gh-aw) Repository Initializer"
echo "   Target Repository: $REPO_ROOT"
echo "================================================================="

# 1. Verify GitHub CLI (gh)
if ! command -v gh &>/dev/null; then
  echo "❌ Error: GitHub CLI ('gh') is not installed."
  echo "   Install via Homebrew: brew install gh"
  exit 1
fi

# 2. Verify / Install gh-aw extension
export PATH="${HOME}/.local/share/gh/extensions/gh-aw:${PATH}"
if ! gh aw version &>/dev/null; then
  echo "📦 Installing gh-aw extension from upstream..."
  curl -sL https://raw.githubusercontent.com/github/gh-aw/main/install-gh-aw.sh | bash
fi

GH_AW_VER="$(gh aw version 2>/dev/null || echo 'unknown')"
echo "✅ gh-aw extension active: $GH_AW_VER"

# 3. Run gh aw init
echo "⚙️ Initializing repository settings..."
gh aw init "$@"

# 4. Compile workflows if any exist in .github/workflows
if ls .github/workflows/*.md &>/dev/null; then
  echo "🔨 Compiling agentic markdown workflows..."
  gh aw compile
fi

echo "================================================================="
echo "🎉 Repository successfully configured for Agentic Workflows!"
echo "   Next steps:"
echo "   - Add workflows from catalog: gh aw add <workflow-name>"
echo "   - Create new workflow:        gh aw new <workflow-name>"
echo "   - Run locally with act:       ./scripts/gh-aw-local-runner.sh"
echo "================================================================="
