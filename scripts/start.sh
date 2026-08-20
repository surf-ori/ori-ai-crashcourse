#!/usr/bin/env bash
set -euo pipefail

# Starts your AI coding agent inside a Docker Sandbox.
#
# Usage: ./scripts/start.sh [opencode|claude]
# Remembers which agent you picked last time in .ori-agent (not committed).
# Remembers a passing preflight in .ori-preflight (not committed) so repeat
# starts skip the ~2-4 minute check. Delete that file to force a recheck --
# see docs/troubleshooting.md.

AGENT_FILE=".ori-agent"
PREFLIGHT_CACHE=".ori-preflight"

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

# preflight.sh runs its checks directly (no sandbox) when sbx isn't found --
# e.g. Codespaces or another devcontainer, which is already isolated. Either
# way, run it: it's the only thing that verifies the AI Hub key actually
# works before you're mid-conversation with the agent.
#
# Skip it if a previous run already passed for this same agent -- the cache
# file is just KEY=VALUE lines, sourced directly, not parsed.
PREFLIGHT_STATUS=""
PREFLIGHT_AGENT=""
PREFLIGHT_CHECKED_AT=""
if [ -f "$PREFLIGHT_CACHE" ]; then
  # shellcheck disable=SC1090
  . "./$PREFLIGHT_CACHE"
fi

if [ "$PREFLIGHT_STATUS" = "ok" ] && [ "$PREFLIGHT_AGENT" = "$AGENT" ]; then
  echo "Setup already checked on $PREFLIGHT_CHECKED_AT -- skipping preflight."
  echo "(Delete $PREFLIGHT_CACHE to force a recheck. See docs/troubleshooting.md.)"
  echo ""
else
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
  printf 'PREFLIGHT_STATUS=ok\nPREFLIGHT_AGENT=%s\nPREFLIGHT_CHECKED_AT=%s\n' \
    "$AGENT" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$PREFLIGHT_CACHE"
fi
echo "You're about to enter $AGENT."
echo "Once inside, type /skills to see what your agent already knows how to do."
echo ""

if command -v sbx >/dev/null 2>&1; then
  exec sbx run "$AGENT" .
else
  exec "$AGENT"
fi
