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

When telling the participant how to preview their notebook, always say
`uvx marimo edit --sandbox --watch notebooks/<slug>/notebook.py`, for
**them** to run in their own sandbox session — never bare `marimo edit
...`, and don't run it yourself via your own shell tool (it starts a
long-running server and would just hang the tool call). Nothing in the
sandbox has `marimo` on `PATH` directly; it only exists as a
`uvx`-managed ephemeral install driven by the PEP 723 header. A
participant who copies a bare `marimo edit` command into their own *host*
terminal will get `command not found`, since their host has no Python
tooling installed at all — that's expected, not a bug to chase.

**`--sandbox` is not optional.** `uvx marimo edit` launches `marimo`
itself in an ephemeral environment containing only marimo's own
dependencies — not the notebook's. Without `--sandbox`, the moment a cell
does `import duckdb` (or `altair`, `pandas`, `pyarrow`) it fails with
`ModuleNotFoundError`, even though the file has a correct PEP 723 header.
`--sandbox` is what makes marimo read that header and install the
notebook's own declared dependencies before running it. Verified directly: `uvx marimo export html --no-sandbox` on the template
throws `ModuleNotFoundError: No module named 'altair'`; the identical
command with `--sandbox` exports cleanly. Always pass `--sandbox`
explicitly — don't assume a default. `marimo check` won't catch this
gap either way — it's a static linter and never imports the notebook's
own deps, which is exactly why it went unnoticed here for a while.
`--watch` reloads the running preview automatically whenever the file
changes on disk — which is what makes it safe to tell a participant "keep
that browser tab open" while you edit cells for them; see
`docs/participant-quickstart.md` Step 4 for how this fits into the
build loop.

When you finish building or changing a notebook, always close with: how
to preview it (the command above), that they can ask you for further
changes by naming the cell ("change the query in `dutch_institutions_query`
to..." — this is exactly why every cell has a name), that
`uvx marimo run --sandbox notebooks/<slug>/notebook.py` shows the
no-code "app mode" view (what a reader actually sees, useful for a final
check before submitting), and that `./scripts/submit.sh <slug>` is the
next step once they're happy with it. Don't just say "Done!" and stop —
the participant may not know the loop continues.

## Marimo notebook conventions

Mistakes that have shown up in real submissions, on top of what
`.claude/skills/marimo-notebook/` already covers:

- **Name every cell.** `def _():` is fine for throwaway experiments in
  `marimo edit`, but a submitted notebook should read like
  `notebooks/_template/notebook.py`: `wasm_dependencies`, `imports`,
  `duckdb_connection`, `dutch_institutions_query`,
  `dutch_institutions_table`, `outro`. A named cell tells a reviewer what
  it's for without opening the browser UI, and it makes the `git diff` on
  a PR legible.
- **Keep SQL cells pure SQL.** marimo has a native SQL cell --
  `mo.sql(f"""...""", engine=con, output=False)` -- and it should contain
  *only* the query. If the query needs to be built from Python (a loop, an
  `if`, string interpolation beyond a plain f-string), do that in a
  preceding cell and pass the result in; don't bury Python control flow
  inside the SQL cell. `notebooks/_template/notebook.py` shows the split:
  one cell runs the query with `output=False`, the next renders the result
  with `mo.ui.table()` or a chart.
- **`mo.md(...)` has no `.followed_by()`.** It doesn't exist, and calling
  it fails at runtime (`AttributeError`), not at `marimo check` time --
  `marimo check` is a static linter and doesn't catch a bad attribute
  access, only `uv run <notebook.py>` will. To show a heading next to a
  table or chart from one cell, use `mo.vstack([mo.md("..."), the_table])`
  (or `mo.hstack` for a row); the repo's own convention is simpler still --
  just use a separate cell per output, like the template does.
- **Don't reuse a plain variable name for cell-local, throwaway output.**
  A cell whose only job is `mo.md("## Some heading")` with nothing to hand
  to later cells should assign it as `_ = mo.md(...)`, not `heading = ...`
  or `md = ...`. Two "just show a heading" cells with the same plain name
  is exactly how you get `MultipleDefinitionError` -- it happened live
  while fixing the `.followed_by()` mistake above, in the same notebook,
  immediately after being warned about `marimo check`'s
  `markdown-indentation` rule. Underscore-prefix on sight for anything
  that's genuinely cell-local; don't wait for `marimo check` to tell you.

Before calling a notebook done, run `uvx marimo check <notebook.py>` and
`uv run <notebook.py>` yourself -- don't just read the diff and assume it
works. `marimo check` catches things like a `MultipleDefinitionError` (the
same un-prefixed variable name, e.g. `chart`, assigned in two different
cells -- prefix cell-local names you don't need to return with `_`) and a
dangling `if` branch whose expression never renders, both instantly and
both before a participant or reviewer ever opens the file. `scripts/submit.sh`
now also runs `marimo check` as a submission gate, but that's a backstop,
not a substitute for checking your own work as you go.

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

`duckdb-fundamentals` is the one deliberate exception: it's hand-written,
not vendored, and has no `skills-lock.json` entry. `duckdb/duckdb-skills`
(the obvious upstream source) is built around a standalone `duckdb` CLI
binary on `PATH` — its `install-duckdb` skill's whole job is installing
that binary, which conflicts with this repo's uvx-only, nothing-on-PATH
model. Don't "fix" this one back to a vendored pack without solving that
mismatch first.

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
