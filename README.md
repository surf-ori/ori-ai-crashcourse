# ORI Crash Course

`git clone`, run one script, and you're talking to a capable AI coding
agent with every relevant skill already loaded — no Node troubleshooting,
no API wiring, under two minutes. You'll leave with a Marimo notebook and
a pull request.

```bash
git clone https://github.com/surf-ori/ori-ai-crashcourse.git
cd ori-ai-crashcourse
./scripts/preflight.sh   # do this a few days ahead, not the morning of
./scripts/start.sh       # on the day
```

New here? Start with `docs/participant-quickstart.md`. Facilitating a
session? Start with `docs/facilitator-guide.md`.

## Agent-agnostic, on purpose

This repo works identically whether you run **OpenCode** or **Claude
Code**. Neither is a second-class path: same skills, same MCP server, same
notebook template, same submission flow. `./scripts/start.sh` asks which
one you want and remembers your choice.

**One honest difference, worth knowing up front:** OpenCode runs on the
SURF AI Hub, using the shared workshop key — your prompts and data stay on
Dutch infrastructure, under your institution's contract. Claude Code
cannot use that key (the AI Hub speaks the OpenAI API shape, Claude Code
expects Anthropic's), so it runs on your own subscription, and your
prompts leave the Netherlands. Same skills, same notebook, different
jurisdiction. Choose OpenCode unless you have a specific reason not to.

## Skills, vendored once

Every skill both agents need is already checked into `.claude/skills/` —
committed to the repo, not fetched at install time, so it works even
behind an institutional proxy with no working npm. This is the *only*
skills directory in the repo, deliberately: Claude Code reads
`.claude/skills/` natively, and OpenCode reads it too alongside
`.agents/skills/`, so one copy serves both agents with no symlinks and
nothing to keep in sync. See `AGENTS.md` for the full rationale.

## What you'll build

A [Marimo](https://marimo.io) notebook answering a real question about
Dutch open research information — data quality, funding, open access,
international collaboration. `docs/ideas.md` has twelve to start from,
across three tiers from operational to leadership-facing. Real examples
from past sessions: https://surf-ori.github.io/dashboards/

```bash
./scripts/new-notebook.sh my-question-slug
# ... build, with your agent ...
./scripts/submit.sh
```

## If something breaks

`docs/troubleshooting.md` covers the common failure modes, symptom to fix.
