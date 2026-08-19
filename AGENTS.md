# Agent conventions — ORI Crash Course

Read this before doing anything else in this repo.

## What you're building

The deliverable is a **Marimo notebook** under `notebooks/<slug>/`,
following the `surf-ori/dashboards` contract exactly so it can be merged
there with light review:

```
notebooks/<slug>/
├── notebook.py       # PEP 723 header, marimo.App(width="full", ...)
├── metadata.json      # title, image, authors[]
└── public/            # screenshots, static assets referenced by metadata.json
```

Start every new notebook with `./scripts/new-notebook.sh <slug>` — it
copies `notebooks/_template/` and substitutes the title. Don't hand-roll a
notebook directory from scratch; the template already has the PEP 723
header, the WASM `micropip` guard, and a working first query wired up.

Slugs are lowercase, hyphenated, no spaces: `dutch-institution-count`, not
`Dutch Institution Count` or `dutch_institution_count`.

## Skills live in `.claude/skills/`, and only there

This is a deliberate departure from `.agents/skills/`, which sibling repos
(`surf-ori/ducklake-overview`) use. Reason, verified against source rather
than assumed from docs: Claude Code discovers `.claude/skills/<name>/SKILL.md`
natively. OpenCode's skill discovery (`packages/opencode/src/skill/index.ts`
in `sst/opencode`) hard-codes `CLAUDE_EXTERNAL_DIR = ".claude"` alongside
`AGENTS_EXTERNAL_DIR = ".agents"` and scans both — on by default, no flag
needed. So `.claude/skills/` is the one location both agents already read.
One copy, no symlinks (which silently fail on Windows without developer
mode), no second directory to drift out of sync.

If you ever "fix" this back to `.agents/skills/`, you are duplicating a
working setup for no reason. Don't.

Skills were vendored once, via `npx skills add <source> --agent claude-code
--copy --yes`, and are tracked in git — not fetched at install time. See
`skills-lock.json` for provenance (source repo, hash) of each one.

## Two model lanes, one repo

`opencode.json` configures the `surf-aihub` provider for OpenCode.
`.mcp.json` configures the same `ori-ducklake` MCP server for Claude Code.
Claude Code participants bring their own Anthropic subscription — see
`README.md` for why the AI Hub key doesn't work there.

Never hardcode `SURF_AIHUB_API_KEY`. It's referenced as `{env:SURF_AIHUB_API_KEY}`
in `opencode.json` and nowhere else. If you're ever about to type the literal
key into a file, stop.

## Data access

The `ori-ducklake` MCP server is the primary way to query the SURF ORI
DuckLake catalog (OpenAlex, OpenAIRE, CRIS, OpenAPC). The `ori-ducklake`
skill has the schema cheat-sheet and query patterns — read it before
guessing a column name. `describe_table` is slow on large tables
(runs `COUNT(*)`); prefer `catalog_stats` first.

Never `UNNEST` authorships on `openalex.works` unfiltered — it's 364M rows.
Filter first, aggregate second.

## Conventions

- Scripts: `set -euo pipefail`, plain-language errors, last line is the one
  a panicking reader sees.
- Commit per concern; keep diffs reviewable.
- Before any commit, grep the staged diff for anything resembling a
  credential and abort if found — `submit.sh` does this automatically for
  notebook submissions.
