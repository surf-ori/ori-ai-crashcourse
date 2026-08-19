#!/usr/bin/env bash
set -euo pipefail

# ORI Crash Course preflight check.
#
# Run this before the workshop. You want every line below to end in a
# green check. If a line is red, read the message under it, then check
# docs/troubleshooting.md before asking for help.
#
# Usage: ./scripts/preflight.sh [opencode|claude]
# Defaults to opencode. You can also set ORI_AGENT=claude instead of
# passing an argument.

EXPECTED_SKILLS=25
COLD_START_SECONDS=20
AGENT="${1:-${ORI_AGENT:-opencode}}"
SANDBOX_NAME="ori-preflight-$$"
FAILED=0

pass() { printf '✅ %s\n' "$1"; }
fail() { printf '❌ %s\n' "$1"; printf '   %s\n' "$2"; FAILED=1; }
note() { printf '⚠️  %s\n' "$1"; printf '   %s\n' "$2"; }

HAS_SBX=1
if ! command -v sbx >/dev/null 2>&1; then
  HAS_SBX=0
fi

cleanup() {
  if [ "$HAS_SBX" -eq 1 ]; then
    sbx rm --force "$SANDBOX_NAME" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [ "$AGENT" != "opencode" ] && [ "$AGENT" != "claude" ]; then
  echo "Unknown agent '$AGENT'. Use 'opencode' or 'claude', e.g.:"
  echo "  ./scripts/preflight.sh claude"
  exit 1
fi

echo "Checking your setup for the $AGENT lane..."
echo ""

if [ "$HAS_SBX" -eq 1 ]; then
  # 1. sbx on PATH and logged in
  if sbx ls >/dev/null 2>&1; then
    pass "sbx installed and logged in"
  else
    fail "sbx installed and logged in" "Install Docker Sandboxes and run 'sbx login'. See docs/participant-quickstart.md Step 1."
    echo ""
    echo "Cannot continue without sbx. Fix this first, then run this script again."
    exit 1
  fi

  # 2. a sandbox starts
  if sbx create --name "$SANDBOX_NAME" "$AGENT" . >/dev/null 2>&1; then
    pass "sandbox starts"
  else
    fail "sandbox starts" "Could not create a sandbox. Run 'sbx run $AGENT' by hand in this folder to see the real error."
    exit 1
  fi

  run_in_sandbox() {
    sbx exec "$SANDBOX_NAME" bash -lc "$1"
  }

  KEY_HINT="Run 'sbx secret set-custom --host willma.surf.nl --env SURF_AIHUB_API_KEY' and paste the key from your invitation email."
else
  # No sbx here -- most likely Codespaces or another devcontainer, which is
  # already an isolated environment. Run the remaining checks directly
  # instead of via a sandbox.
  note "no sbx found" "Running checks directly against this environment -- this looks like Codespaces or another devcontainer, which is already isolated. Skipping the sbx-specific checks."

  run_in_sandbox() {
    bash -lc "$1"
  }

  KEY_HINT='Add SURF_AIHUB_API_KEY as a Codespaces secret at https://github.com/settings/codespaces, then rebuild the container (Command Palette -> "Codespaces: Rebuild Container").'
fi

# 3 & 4. agent choice + credentials present for the chosen lane
if [ "$AGENT" = "opencode" ]; then
  if run_in_sandbox 'test -n "${SURF_AIHUB_API_KEY:-}"' >/dev/null 2>&1; then
    pass "SURF AI Hub key found"
  else
    fail "SURF AI Hub key found" "$KEY_HINT"
    exit 1
  fi
else
  if run_in_sandbox 'command -v claude >/dev/null 2>&1' >/dev/null 2>&1; then
    pass "Claude Code found (sign in with your own subscription the first time you run it)"
  else
    fail "Claude Code found" "Claude Code isn't available. See docs/troubleshooting.md."
    exit 1
  fi
fi

# 5. model responds to a trivial completion
if [ "$AGENT" = "opencode" ]; then
  START_TIME=$(date +%s)
  HTTP_CODE=$(run_in_sandbox '
    curl -s -m 300 -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $SURF_AIHUB_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"Sehyo/Qwen3.5-122B-A10B-NVFP4\",\"messages\":[{\"role\":\"user\",\"content\":\"reply with the word ok\"}]}" \
      https://willma.surf.nl/api/v0/chat/completions
  ' 2>/dev/null || echo "000")
  END_TIME=$(date +%s)
  ELAPSED=$((END_TIME - START_TIME))

  if [ "$HTTP_CODE" = "200" ]; then
    pass "model responds"
  else
    fail "model responds" "The AI Hub did not return 200 (got $HTTP_CODE). Check the key hasn't expired, then see docs/troubleshooting.md."
    exit 1
  fi

  if [ "$ELAPSED" -gt "$COLD_START_SECONDS" ]; then
    note "model was cold (${ELAPSED}s to answer)" "Normal for the first request of the day — on-demand models spin up on first use. Run this script again and it should answer in a couple of seconds."
  fi
else
  pass "model responds (Claude Code uses your own subscription, not checked here)"
fi

# 6. model completes a tool call over a streaming request — the check that matters most.
# A non-streaming test passes on models that are broken in OpenCode; this must stream.
if [ "$AGENT" = "opencode" ]; then
  TOOLCALL_OUTPUT=$(run_in_sandbox '
    curl -s -m 300 \
      -H "Authorization: Bearer $SURF_AIHUB_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"Sehyo/Qwen3.5-122B-A10B-NVFP4\",\"stream\":true,\"tools\":[{\"type\":\"function\",\"function\":{\"name\":\"get_time\",\"description\":\"Get the current time\",\"parameters\":{\"type\":\"object\",\"properties\":{}}}}],\"messages\":[{\"role\":\"user\",\"content\":\"What time is it? Use the get_time tool.\"}]}" \
      https://willma.surf.nl/api/v0/chat/completions
  ' 2>/dev/null || true)

  if printf '%s' "$TOOLCALL_OUTPUT" | grep -q 'tool_calls'; then
    pass "model can use tools (streaming)"
  else
    fail "model can use tools (streaming)" "The model did not return a tool call over a streaming request. This is the check that matters most — contact the facilitator rather than retrying."
    exit 1
  fi
else
  pass "model can use tools (Claude Code manages this itself)"
fi

# 7. skills load, count matches expectations
SKILL_COUNT=$(find .claude/skills -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -eq "$EXPECTED_SKILLS" ]; then
  pass "skills loaded ($SKILL_COUNT)"
else
  fail "skills loaded ($SKILL_COUNT)" "Expected $EXPECTED_SKILLS skills in .claude/skills/. Try a fresh 'git clone' — see docs/troubleshooting.md."
fi

# 8. git present, github.com reachable
if command -v git >/dev/null 2>&1 && curl -s -o /dev/null -m 10 https://github.com; then
  pass "git and GitHub reachable"
else
  fail "git and GitHub reachable" "Install git and make sure your network can reach github.com."
fi

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "All green. Reply to the invitation email with a screenshot of this output."
else
  echo "Something above needs fixing. Check docs/troubleshooting.md, then run this script again."
  exit 1
fi
