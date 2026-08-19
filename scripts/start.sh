#!/usr/bin/env bash
set -euo pipefail

# Starts your AI coding agent inside a Docker Sandbox.
#
# Usage: ./scripts/start.sh [opencode|claude]
# Remembers which agent you picked last time in .ori-agent (not committed).

AGENT_FILE=".ori-agent"

if [ -n "${1:-}" ]; then
  AGENT="$1"
elif [ -f "$AGENT_FILE" ]; then
  AGENT=$(cat "$AGENT_FILE")
else
  echo "Which agent do you want to use?"
  echo "  1) opencode  (SURF AI Hub, default)"
  echo "  2) claude    (your own Claude subscription)"
  read -r -p "Choice [1]: " CHOICE
  case "$CHOICE" in
    2) AGENT="claude" ;;
    *) AGENT="opencode" ;;
  esac
fi

if [ "$AGENT" != "opencode" ] && [ "$AGENT" != "claude" ]; then
  echo "Unknown agent '$AGENT'. Use 'opencode' or 'claude'."
  exit 1
fi

echo "$AGENT" > "$AGENT_FILE"

if ! command -v sbx >/dev/null 2>&1; then
  # No sbx here -- most likely a Codespace or other devcontainer, which is
  # already an isolated environment on its own. Skip the sbx-based
  # preflight (it would just fail on "sbx installed") and launch the
  # agent directly instead.
  echo "sbx not found -- running $AGENT directly (this looks like Codespaces"
  echo "or another devcontainer, which is already isolated)."
  echo ""
  echo "You're about to enter $AGENT."
  echo "Once inside, type /skills to see what your agent already knows how to do."
  echo ""
  exec "$AGENT"
fi

echo "Checking your setup..."
PREFLIGHT_LOG=$(mktemp)
if ! ./scripts/preflight.sh "$AGENT" > "$PREFLIGHT_LOG" 2>&1; then
  echo ""
  echo "Setup isn't ready yet. Here's what failed:"
  grep '❌' "$PREFLIGHT_LOG" || tail -n 10 "$PREFLIGHT_LOG"
  echo ""
  echo "Fix this before starting. See docs/troubleshooting.md."
  rm -f "$PREFLIGHT_LOG"
  exit 1
fi
rm -f "$PREFLIGHT_LOG"
echo "Setup looks good."
echo ""
echo "You're about to enter the sandbox running $AGENT."
echo "Once inside, type /skills to see what your agent already knows how to do."
echo ""

exec sbx run "$AGENT" .
