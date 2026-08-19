#!/usr/bin/env bash
set -euo pipefail

# Codespaces / devcontainer setup. Runs once when the container is created.
# Same repo, same skills, same agents as the sbx lane -- just no sbx here,
# since the devcontainer/Codespace is already the isolated environment.

echo "Installing uv (for marimo and the DuckLake MCP server)..."
curl -LsSf https://astral.sh/uv/install.sh | sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

echo "Installing OpenCode..."
npm install -g opencode-ai

echo "Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

chmod +x scripts/*.sh

echo ""
echo "Setup done. Skills are already vendored in .claude/skills/ -- nothing"
echo "more to install there."
echo ""
echo "Before you start: add your SURF_AIHUB_API_KEY as a Codespaces secret"
echo "(https://github.com/settings/codespaces) if you're using OpenCode --"
echo "it'll appear as an environment variable automatically, no extra setup"
echo "needed here. Claude Code users: run 'claude' once and sign in."
echo ""
echo "Then run: ./scripts/start.sh"
