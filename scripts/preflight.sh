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
#
# This can take several minutes -- the sandbox and model checks are the
# slow part, not a bug. Set ORI_PREFLIGHT_VERBOSE=1 to always show live
# detail during a slow step instead of just a spinner; in an interactive
# terminal you can also press 'v' at any time during a step to switch it
# on for the rest of the run.

EXPECTED_SKILLS=26
COLD_START_SECONDS=20
AGENT="${1:-${ORI_AGENT:-opencode}}"
SANDBOX_NAME="ori-preflight-$$"
FAILED=0
STEP=0

pass() { printf '✅ %s\n' "$1"; }
fail() { printf '❌ %s\n' "$1"; printf '   %s\n' "$2"; FAILED=1; }
note() { printf '⚠️  %s\n' "$1"; printf '   %s\n' "$2"; }
step() { STEP=$((STEP + 1)); printf '\n[%d/%d] %s\n' "$STEP" "$TOTAL_STEPS" "$1"; }

# Only spin/redraw with \r in a real terminal. When output is redirected to
# a file (start.sh does this), print an occasional heartbeat line instead --
# otherwise every redraw frame becomes its own line and the log balloons.
INTERACTIVE=0
if [ -t 0 ] && [ -t 1 ]; then
  INTERACTIVE=1
fi
SPIN='|/-\'

# Runs "$@" in the background, showing a spinner with elapsed time while it
# works. In an interactive terminal, pressing 'v' switches to showing the
# command's latest output line instead of just the spinner -- useful when
# you want to see *what* it's doing, not just that it's still alive.
# Sets PROGRESS_LOG to a temp file with the command's full output; caller
# is responsible for `rm -f "$PROGRESS_LOG"` when done with it.
run_with_progress() {
  local desc="$1"
  shift
  local logfile
  logfile="$(mktemp)"
  "$@" >"$logfile" 2>&1 &
  local pid=$!
  local verbose="${ORI_PREFLIGHT_VERBOSE:-0}"
  local start now elapsed i=0 last_report=0 c last key

  start=$(date +%s)
  while kill -0 "$pid" 2>/dev/null; do
    now=$(date +%s)
    elapsed=$((now - start))
    if [ "$INTERACTIVE" -eq 1 ]; then
      c="${SPIN:$((i % 4)):1}"
      i=$((i + 1))
      if [ "$verbose" = "1" ]; then
        last="$(tail -n 1 "$logfile" 2>/dev/null | tr -d '\r\n' | cut -c1-70)"
        printf '\r   [%s] %s (%ss)  %s\033[K' "$c" "$desc" "$elapsed" "$last"
      else
        printf '\r   [%s] %s (%ss) -- press v for details\033[K' "$c" "$desc" "$elapsed"
      fi
      if read -r -t 0.3 -n 1 -s key 2>/dev/null; then
        [ "$key" = "v" ] && verbose=1
      fi
    else
      if [ $((elapsed - last_report)) -ge 15 ]; then
        printf '   ... still %s (%ss elapsed)\n' "$desc" "$elapsed"
        last_report=$elapsed
      fi
      sleep 1
    fi
  done

  local status=0
  wait "$pid" || status=$?
  [ "$INTERACTIVE" -eq 1 ] && printf '\r\033[K'
  PROGRESS_LOG="$logfile"
  return $status
}

# Portable timeout: the GNU `timeout` command isn't installed on stock
# macOS, so this can't rely on it. Runs "$@" in the background and kills it
# if it's still running after $1 seconds, so a genuinely stuck command
# (stalled network mid-download, a hung daemon) fails with a clear message
# after a bounded wait instead of hanging the whole script forever.
run_with_timeout() {
  local secs="$1"
  shift
  "$@" &
  local cmd_pid=$!
  (
    sleep "$secs"
    kill -TERM "$cmd_pid" 2>/dev/null
  ) &
  local watchdog_pid=$!
  local status=0
  wait "$cmd_pid" 2>/dev/null || status=$?
  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true
  if [ "$status" -eq 143 ]; then
    echo "Timed out after ${secs}s waiting for: $*" >&2
  fi
  return $status
}

HAS_SBX=1
if ! command -v sbx >/dev/null 2>&1; then
  HAS_SBX=0
fi

if [ "$HAS_SBX" -eq 1 ]; then
  TOTAL_STEPS=8
else
  TOTAL_STEPS=6
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
if [ "$INTERACTIVE" -eq 1 ]; then
  echo "This can take several minutes. Press 'v' during any step to see live detail."
fi

if [ "$HAS_SBX" -eq 1 ]; then
  # 1. sbx on PATH and logged in
  step "sbx installed and logged in"
  if sbx ls >/dev/null 2>&1; then
    pass "sbx installed and logged in"
  else
    fail "sbx installed and logged in" "Install Docker Sandboxes and run 'sbx login'. See docs/participant-quickstart.md Step 1."
    echo ""
    echo "Cannot continue without sbx. Fix this first, then run this script again."
    exit 1
  fi

  # 2. a sandbox starts
  step "sandbox starts -- first run can take a few minutes, it's downloading a VM image"
  if run_with_progress "starting your sandbox" run_with_timeout 600 sbx create --name "$SANDBOX_NAME" "$AGENT" .; then
    pass "sandbox starts"
    rm -f "$PROGRESS_LOG"
  else
    fail "sandbox starts" "Could not create a sandbox in 10 minutes. Run 'sbx run $AGENT' by hand in this folder to see the real error -- the output below is what was captured before it gave up."
    cat "$PROGRESS_LOG"
    rm -f "$PROGRESS_LOG"
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
  step "SURF AI Hub key found"
  if run_in_sandbox 'test -n "${SURF_AIHUB_API_KEY:-}"' >/dev/null 2>&1; then
    pass "SURF AI Hub key found"
  else
    fail "SURF AI Hub key found" "$KEY_HINT"
    exit 1
  fi
else
  step "Claude Code found"
  if run_in_sandbox 'command -v claude >/dev/null 2>&1' >/dev/null 2>&1; then
    pass "Claude Code found (sign in with your own subscription the first time you run it)"
  else
    fail "Claude Code found" "Claude Code isn't available. See docs/troubleshooting.md."
    exit 1
  fi
fi

# 5. model responds to a trivial completion
if [ "$AGENT" = "opencode" ]; then
  step "model responds -- can take up to 4 minutes if the model is cold"
  MODEL_CHECK_START=$(date +%s)
  if run_with_progress "waiting for the model to respond" run_in_sandbox '
    curl -s -m 300 -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $SURF_AIHUB_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"Sehyo/Qwen3.5-122B-A10B-NVFP4\",\"messages\":[{\"role\":\"user\",\"content\":\"reply with the word ok\"}]}" \
      https://willma.surf.nl/api/v0/chat/completions
  '; then
    HTTP_CODE="$(cat "$PROGRESS_LOG")"
  else
    HTTP_CODE="000"
  fi
  rm -f "$PROGRESS_LOG"
  ELAPSED=$(( $(date +%s) - MODEL_CHECK_START ))

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
  step "model responds"
  pass "model responds (Claude Code uses your own subscription, not checked here)"
fi

# 6. model completes a tool call over a streaming request — the check that matters most.
# A non-streaming test passes on models that are broken in OpenCode; this must stream.
if [ "$AGENT" = "opencode" ]; then
  step "model can use tools (streaming) -- the check that matters most"
  if run_with_progress "waiting for a streaming tool call" run_in_sandbox '
    curl -s -m 300 \
      -H "Authorization: Bearer $SURF_AIHUB_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"Sehyo/Qwen3.5-122B-A10B-NVFP4\",\"stream\":true,\"tools\":[{\"type\":\"function\",\"function\":{\"name\":\"get_time\",\"description\":\"Get the current time\",\"parameters\":{\"type\":\"object\",\"properties\":{}}}}],\"messages\":[{\"role\":\"user\",\"content\":\"What time is it? Use the get_time tool.\"}]}" \
      https://willma.surf.nl/api/v0/chat/completions
  '; then
    TOOLCALL_OUTPUT="$(cat "$PROGRESS_LOG")"
  else
    TOOLCALL_OUTPUT=""
  fi
  rm -f "$PROGRESS_LOG"

  if printf '%s' "$TOOLCALL_OUTPUT" | grep -q 'tool_calls'; then
    pass "model can use tools (streaming)"
  else
    fail "model can use tools (streaming)" "The model did not return a tool call over a streaming request. This is the check that matters most — contact the facilitator rather than retrying."
    exit 1
  fi
else
  step "model can use tools"
  pass "model can use tools (Claude Code manages this itself)"
fi

# 7. skills load, count matches expectations
step "skills loaded"
SKILL_COUNT=$(find .claude/skills -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILL_COUNT" -eq "$EXPECTED_SKILLS" ]; then
  pass "skills loaded ($SKILL_COUNT)"
else
  fail "skills loaded ($SKILL_COUNT)" "Expected $EXPECTED_SKILLS skills in .claude/skills/. Try a fresh 'git clone' — see docs/troubleshooting.md."
fi

# 7b. git can actually reach GitHub from inside the sandbox. The sandbox's
# network proxy needs a "github" secret configured before *any* git-over-
# HTTPS traffic works -- even a plain clone of a public repo fails without
# one. This is what the ori-ducklake MCP server and submit.sh's git push
# both depend on.
step "git can reach GitHub from inside the sandbox"
if run_in_sandbox 'GIT_TERMINAL_PROMPT=0 timeout 20 git ls-remote https://github.com/surf-ori/agentic-tools >/dev/null 2>&1'; then
  pass "git can reach GitHub from inside the sandbox"
else
  if [ "$HAS_SBX" -eq 1 ]; then
    fail "git can reach GitHub from inside the sandbox" "Run 'sbx secret set github' and paste a GitHub personal access token (repo scope, from https://github.com/settings/tokens/new). Needed for the ori-ducklake MCP server and for submit.sh's git push."
  else
    fail "git can reach GitHub from inside the sandbox" "Codespaces should authenticate git automatically. See docs/troubleshooting.md."
  fi
fi

# 8. git present, github.com reachable
step "git and GitHub reachable"
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
