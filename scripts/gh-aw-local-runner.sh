#!/usr/bin/env bash
# ==============================================================================
# Local GitHub Agentic Workflows Runner (Sandboxed Subagent)
#
# Replaces Docker with a native Sandboxed Subagent Runner:
# - Zero Docker daemon overhead or container virtualization
# - Emulates GitHub Actions environment ($GITHUB_ENV, $GITHUB_OUTPUT, $RUNNER_TEMP)
# - Direct execution inside sandboxed subagent process isolation
# - Supports --docker flag to fall back to act if container virtualization is desired
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Ensure PATH includes bun, brew, and gh
export PATH="${HOME}/.bun/bin:/opt/homebrew/bin:/usr/local/bin:${HOME}/.local/share/gh/extensions/gh-aw:${PATH}"

# 1. Resolve JS/TS runtime (prefer Bun for instant execution, fallback to tsx/node)
if [ -x "${HOME}/.bun/bin/bun" ]; then
  RUNNER_CMD="${HOME}/.bun/bin/bun"
elif command -v bun &>/dev/null; then
  RUNNER_CMD="bun"
elif command -v tsx &>/dev/null; then
  RUNNER_CMD="tsx"
else
  RUNNER_CMD="npx tsx"
fi

# 2. Recompile agentic workflows to ensure lock files are fresh if any .md workflows exist
if compgen -G ".github/workflows/*.md" > /dev/null; then
  echo "🔨 Compiling agentic markdown workflows..."
  gh aw compile 2>/dev/null || true
fi

# 3. Check if user requested Docker fallback mode
USE_DOCKER=false
FILTERED_ARGS=()
for arg in "$@"; do
  if [ "$arg" == "--docker" ]; then
    USE_DOCKER=true
  else
    FILTERED_ARGS+=("$arg")
  fi
done

if [ "$USE_DOCKER" = true ]; then
  echo "🐳 Running in Docker mode via act..."
  if ! command -v act &>/dev/null; then
    echo "❌ Error: 'act' is not installed. Install via Homebrew: brew install act"
    exit 1
  fi
  exec act "${FILTERED_ARGS[@]}"
fi

# 4. Default: Run native Sandboxed Subagent Runner (Zero Docker Daemon)
exec "$RUNNER_CMD" scripts/subagent-workflow-runner.ts "${FILTERED_ARGS[@]}"
