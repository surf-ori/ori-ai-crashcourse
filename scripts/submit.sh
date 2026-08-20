#!/usr/bin/env bash
set -euo pipefail

# Submits your notebook as a pull request.
# Usage: ./scripts/submit.sh [slug]

SLUG="${1:-}"

if [ -z "$SLUG" ]; then
  CANDIDATES=$(find notebooks -mindepth 1 -maxdepth 1 -type d ! -name "_template" -exec basename {} \; 2>/dev/null || true)
  CANDIDATE_COUNT=$(printf '%s\n' "$CANDIDATES" | grep -c . || true)

  if [ "$CANDIDATE_COUNT" -eq 1 ]; then
    SLUG="$CANDIDATES"
    echo "Found one notebook: $SLUG"
  elif [ "$CANDIDATE_COUNT" -eq 0 ]; then
    echo "No notebooks found under notebooks/. Run ./scripts/new-notebook.sh <slug> first."
    exit 1
  else
    echo "Which notebook do you want to submit?"
    printf '%s\n' "$CANDIDATES"
    read -r -p "Slug: " SLUG
  fi
fi

NOTEBOOK_DIR="notebooks/$SLUG"
if [ ! -d "$NOTEBOOK_DIR" ]; then
  echo "notebooks/$SLUG doesn't exist."
  exit 1
fi

echo "Scanning your notebook for anything that looks like a credential..."
git add "$NOTEBOOK_DIR"
DIFF_OUTPUT=$(git diff --cached -- "$NOTEBOOK_DIR")
if printf '%s' "$DIFF_OUTPUT" | grep -qiE 'api[_-]?key\s*[:=]\s*["\x27]?[a-zA-Z0-9_\-]{16,}|secret\s*[:=]\s*["\x27]?[a-zA-Z0-9_\-]{16,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'; then
  git reset -- "$NOTEBOOK_DIR" >/dev/null
  echo ""
  echo "STOP: something in your notebook looks like a credential."
  echo "Do not submit. Remove it, then run this script again."
  echo "If you already committed it anywhere, tell the facilitator immediately so it can be revoked."
  exit 1
fi
echo "Nothing suspicious found."
echo ""

GITHUB_HANDLE=$(gh api user --jq .login 2>/dev/null || true)
if [ -z "$GITHUB_HANDLE" ]; then
  GITHUB_HANDLE=$(git config user.name 2>/dev/null | tr '[:upper:] ' '[:lower:]-' || true)
fi
if [ -z "$GITHUB_HANDLE" ]; then
  GITHUB_HANDLE="participant"
fi

BRANCH="notebook/${GITHUB_HANDLE}-${SLUG}"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
  git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
fi

if ! git commit -m "notebook: $SLUG"; then
  echo ""
  echo "Nothing new to commit for $SLUG -- re-checking your last submission."
fi

PUSHED=0
if git push -u origin "$BRANCH" 2>/dev/null; then
  PUSHED=1
fi

# origin is your fork (see docs/participant-quickstart.md Step 2), not the
# shared repo -- derive the fork owner from it so the fallback PR link
# compares against the upstream repo, not your own fork.
UPSTREAM="https://github.com/surf-ori/ori-ai-crashcourse"
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || true)
FORK_OWNER=$(printf '%s' "$ORIGIN_URL" | sed -E 's#^(https://github\.com/|git@github\.com:)([^/]+)/.*#\2#')

if [ "$PUSHED" -eq 1 ] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh pr create --fill && exit 0
fi

if [ -n "$FORK_OWNER" ] && [ "$FORK_OWNER" != "surf-ori" ]; then
  COMPARE_URL="${UPSTREAM}/compare/main...${FORK_OWNER}:${BRANCH}?expand=1"
else
  COMPARE_URL="${UPSTREAM}/compare/${BRANCH}?expand=1"
fi

echo ""
if [ "$PUSHED" -eq 0 ]; then
  echo "Could not push your branch. Check your network, then try again:"
  echo "  git push -u origin $BRANCH"
fi
echo "Open a pull request by hand at:"
echo "  ${COMPARE_URL}"
echo ""
echo "If that doesn't work either, use the 'Workshop idea' issue template on your"
echo "phone instead and paste your notebook in. Your idea gets captured either way."
