#!/usr/bin/env bash
# ==============================================================================
# Local GitHub Agentic Workflows Runner using `act`
#
# Executes GitHub Actions & compiled Agentic Workflows locally inside Docker
# without pushing to remote or waiting for cloud runners.
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Ensure PATH includes Homebrew and gh extensions
export PATH="/opt/homebrew/bin:/usr/local/bin:${HOME}/.local/share/gh/extensions/gh-aw:${PATH}"

# 1. Verify act runner
if ! command -v act &>/dev/null; then
  echo "❌ Error: 'act' local runner is not installed."
  echo "   Install via Homebrew: brew install act"
  exit 1
fi

# 2. Ensure non-interactive ~/.actrc exists with Apple Silicon container architecture
if [ ! -f "${HOME}/.actrc" ]; then
  echo "⚙️ Configuring ~/.actrc default container image..."
  cat <<'EOF' > "${HOME}/.actrc"
-P ubuntu-latest=catthehacker/ubuntu:act-latest
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04
-P ubuntu-20.04=catthehacker/ubuntu:act-20.04
--container-architecture linux/amd64
EOF
fi

# 3. Recompile agentic workflows to ensure lock files are up to date
if ls .github/workflows/*.md &>/dev/null; then
  echo "🔨 Compiling agentic markdown workflows..."
  gh aw compile || true
fi

# 4. Resolve environment / secret files
SECRET_FLAG=()
if [ -f ".env" ]; then
  SECRET_FLAG+=(--secret-file ".env" --env-file ".env")
elif [ -f ".secrets" ]; then
  SECRET_FLAG+=(--secret-file ".secrets")
fi

ACTION="${1:-list}"

case "$ACTION" in
  list|-l|--list)
    echo "📋 Listing all available workflows and jobs:"
    act -l
    ;;
  dry-run|-n|--dryrun)
    shift || true
    echo "🧪 Running validation dry-run with act:"
    act -n "${SECRET_FLAG[@]}" "$@"
    ;;
  graph|-g|--graph)
    shift || true
    echo "📊 Workflow execution graph:"
    act -g "$@"
    ;;
  run)
    shift || true
    TARGET="${1:-workflow_dispatch}"
    echo "🚀 Executing workflow '$TARGET' locally via act..."
    act "$TARGET" "${SECRET_FLAG[@]}" "${@:2}"
    ;;
  *)
    echo "🚀 Running act with arguments: $@"
    act "${SECRET_FLAG[@]}" "$@"
    ;;
esac
