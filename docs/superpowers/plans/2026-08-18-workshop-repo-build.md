# ORI Crash Course Workshop Repo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Follow with superpowers:verification-before-completion before claiming any phase done.

**Goal:** Build `surf-ori/ori-ai-crashcourse`, a workshop repo that gets a non-technical participant from `git clone` to a working, skill-loaded AI agent (OpenCode or Claude Code) in under two minutes, ending in a Marimo notebook PR against `surf-ori/dashboards`.

**Architecture:** Skeleton per the brief's Phase 1 tree. Skills vendored once into `.claude/skills/` (verified below: OpenCode's actual discovery code reads this path natively, no `.agents/skills/` duplication needed). Two model lanes — SURF AI Hub for OpenCode (verified endpoint/auth/models), bring-your-own-subscription for Claude Code. Scripts are plain bash/curl, no framework. Notebook template mirrors `surf-ori/dashboards` exactly, verified against that repo's live `ori-data-quality` and `repository-status` notebooks.

**Tech Stack:** bash (`set -euo pipefail`), PowerShell (preflight only), `uv`/`uvx`, Marimo, OpenCode config JSON, Claude Code `.mcp.json`, GitHub Actions.

**Spec:** `/root/.claude/uploads/3bf44965-f309-51c5-b338-c617a94c2ec6/cb74b221-04agentbuildbrief.md` (the four uploaded briefs — build brief, facilitator guide, participant quickstart, rubric).

## Global Constraints

- Credential handling is absolute: `SURF_AIHUB_API_KEY` referenced only as `{env:SURF_AIHUB_API_KEY}`; never the literal key in any file/commit/log; grep the staged diff for the literal key string before every commit and abort if found.
- `.gitignore` must contain `.env`, `*.key`, `.opencode/auth.json`, `.claude/settings.local.json` — written in the **first** commit, before any other file.
- Every script: `set -euo pipefail`, plain-language errors, no jargon, last line is the one a panicking reader sees.
- Commit separately per concern: skeleton, skills, provider config, scripts, template, ideas, docs, CI, devcontainer. Diffs stay reviewable by Till.
- Do not silently resolve the "Open decisions" in the brief (§ Open decisions to flag) — carry them into the PR summary.
- State plainly, per the brief's verification section, what was actually run vs. only read. Never claim a phase verified from reading code alone.

## Pre-work already done (this session, before writing this plan)

Verified against primary sources, not re-derived from the brief:

1. **OpenCode skill discovery is real, not doc-only.** Cloned `sst/opencode` (commit `8b65fa2`, package version `1.18.18`, dated 2026-08-18 — i.e. current). `packages/opencode/src/skill/index.ts` hard-codes `CLAUDE_EXTERNAL_DIR = ".claude"` and `AGENTS_EXTERNAL_DIR = ".agents"`, and `discoverSkills()` scans `<dir>/.claude/skills/**/SKILL.md` and `<dir>/.agents/skills/**/SKILL.md` at both `~` (global) and every directory from cwd up to the git worktree root (project) — **on by default**. It's gated by two env vars, both defaulting to `false`: `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` (also inherits `OPENCODE_DISABLE_CLAUDE_CODE`) and `OPENCODE_DISABLE_EXTERNAL_SKILLS`. **No `.agents/skills/` fallback is needed.** Item 4 of the brief's open decisions is resolved: yes, confirmed in practice (source, not docs).
2. **`npx skills add` is `vercel-labs/skills`** (npm package `skills`, v1.5.23, 39M monthly downloads, supports 76+ agents including `opencode` and `claude-code`). Confirmed from its README:
   - Default install method is **symlink**, not copy (`--copy` opts into real files).
   - It auto-detects installed agents and, absent `-a/--agent`, installs to **all** it detects.
   - Per-agent project paths: `claude-code` → `.claude/skills/`, `opencode` → `.agents/skills/`.
   - Because the workshop sandbox has both `claude` and `opencode` binaries present, a bare `npx skills add DietrichGebert/ponytail --yes` would symlink ponytail into **both** `.claude/skills/` and `.agents/skills/` — violating the brief's own "no symlinks, Windows" rule and creating a second, redundant vendor location we deliberately don't otherwise have.
   - **Exact participant command:** `npx skills add DietrichGebert/ponytail --agent claude-code --copy --yes`. This writes a real copy into `.claude/skills/ponytail/` only — the one location both agents already read (per finding 1) — and never touches the filesystem with a symlink. Document this exact command in `docs/troubleshooting.md` and `docs/participant-quickstart.md`, replacing any bare `npx skills add owner/repo --yes` reference.
3. Cloned `surf-ori/dashboards`, `surf-ori/ducklake-overview`, `surf-ori/agentic-tools` and read their live conventions (see "Corrections to the brief" below).

## Corrections to the brief (from reading the actual sibling repos, not re-deriving)

- **`skills-lock.json` shape**: `surf-ori/dashboards`' own lock file omits `skillPath` (only `source`/`sourceType`/`computedHash`); `surf-ori/ducklake-overview`'s includes it. The brief asks for `skillPath` — going with the fuller shape (ducklake-overview's), since it's more informative and matches the brief explicitly. Flag in PR summary that dashboards' own lock file is the odd one out.
- **`anywidget` skill is actually named `anywidget-generator`** in `marimo-team/skills` (confirmed via dashboards' `skills-lock.json` and this session's own available skills). The brief's Phase 2 table says `anywidget`; correct it.
- **MCP server invocation differs from the brief's `uvx --from git+...` plan.** `dashboards/.mcp.json` actually runs `uv tool run ori-ducklake-mcp` (assumes pre-installed via `uv tool install mcp-servers/ori-ducklake-mcp/`), not a zero-clone `uvx --from git+https://...`. The brief explicitly wants the zero-clone route "so it survives after the session" — that's the right call for a one-off workshop laptop, but the exact `uvx --from "git+https://github.com/surf-ori/agentic-tools#subdirectory=mcp-servers/ori-ducklake-mcp" ori-ducklake-mcp` invocation is **untested in this session** (no live sandbox available to run it) and must be smoke-tested during Task 5 execution, not assumed.
- **`dashboards/AGENTS.md` itself is stale** on one point: it says "MCP server config: `.claude/settings.json`", but the actual live file is root `.mcp.json`. Don't propagate that error into our own `AGENTS.md`.
- **Notebook width**: brief says `width="full"`; dashboards' actual notebooks mix `width="medium"` (simple ones) and `width="full"` (data-quality one, which is the one to mirror per the brief's "produce a chart in ten seconds" instruction). Using `width="full"` per the brief is correct — `ori-data-quality/notebook.py` confirms this pattern along with the `wasm_dependencies` / `micropip` guard cell, verified verbatim.
- **`opencode.json` provider key**: confirmed live in dashboards as `"lmstudio"` — the brief's instruction to rename to `"surf-aihub"` is correct and non-optional; that key is a genuine leftover.

## Task breakdown (commit-per-concern, per the brief's Phase numbering)

### Task 1: Skeleton + `.gitignore` (first commit)
**Files:** full directory tree per brief Phase 1 (empty/placeholder files where content lands in later tasks); `.gitignore` with `.env`, `*.key`, `.opencode/auth.json`, `.claude/settings.local.json`, plus `_site/`, `__marimo__/`, `.venv/`, `uv.lock` (optional, per dashboards' own `.gitignore` convention).
- [ ] Create directory skeleton exactly as Phase 1 lists it.
- [ ] Write `.gitignore` first, commit it alone before any other file exists.
- [ ] Commit: `chore: repo skeleton and gitignore`

### Task 2: Vendor skills into `.claude/skills/`
**Files:** `.claude/skills/<name>/SKILL.md` for the 23-skill final list (below), `skills-lock.json`.
- [ ] Vendor via `npx skills add <source> --agent claude-code --copy --yes` per source repo (obra/superpowers, DietrichGebert/ponytail, surf-ori/agentic-tools, marimo-team/skills, davila7/claude-code-templates), then `--skill` filter down to only the trimmed list — do not vendor the skills being cut.
- [ ] Generate `skills-lock.json` with `npx skills` (not by hand) so hashes are real; confirm shape matches ducklake-overview's (`source`, `sourceType`, `skillPath`, `computedHash`).
- [ ] Verify: `find .claude/skills -name SKILL.md | wc -l` equals the agreed count; no `.agents/skills/` directory was created as a side effect.
- [ ] Note the `.claude/skills/` rationale in `README.md` and `AGENTS.md` (single location, OpenCode reads it natively — cite the source finding above).
- [ ] Commit: `feat: vendor skills into .claude/skills`

### Task 3: Provider config — `opencode.json`, `.mcp.json`
**Files:** `opencode.json` (provider key `surf-aihub`, verified base URL/model table from Phase 3), `.mcp.json` (ori-ducklake MCP server, Claude Code shape).
- [ ] Write `opencode.json` per the brief's verified config block, provider key renamed `surf-aihub`, only the two safe models listed (`Sehyo/Qwen3.5-122B-A10B-NVFP4` default, `RedHatAI/gemma-4-31B-it-NVFP4` fallback), `apiKey: "{env:SURF_AIHUB_API_KEY}"`.
- [ ] Write `.mcp.json` with the `uvx --from "git+https://github.com/surf-ori/agentic-tools#subdirectory=mcp-servers/ori-ducklake-mcp" ori-ducklake-mcp` invocation; smoke-test it actually resolves and starts (this session can test this — no sandbox needed, just `uvx`/`uv` and network).
- [ ] Grep the diff for the literal test key before commit.
- [ ] Commit: `feat: SURF AI Hub and MCP provider config`

### Task 4: Scripts
**Files:** `scripts/preflight.sh`, `scripts/preflight.ps1`, `scripts/start.sh`, `scripts/new-notebook.sh`, `scripts/submit.sh`.
- [ ] `preflight.sh`: the 9 checks from Phase 4, check 6 using `stream: true` + `tools` array against the live endpoint (testable now with the workshop key), check 9 (cold-start warning) added.
- [ ] `preflight.ps1`: PowerShell port, same checks — **cannot be tested in this Linux sandbox**; note this explicitly rather than claiming it works.
- [ ] `start.sh`: agent choice (remembers it), quiet preflight first, `sbx run <agent>` — **`sbx` itself cannot be tested here** (no KVM/Apple Silicon); note explicitly.
- [ ] `new-notebook.sh <slug>`: copy template, validate lowercase-hyphenated slug, substitute title.
- [ ] `submit.sh`: credential-scan the diff, branch `notebook/<handle>-<slug>`, PR via `gh`, print manual PR URL fallback if `gh` missing/unauthenticated.
- [ ] Verify: `bash -n` (or `shellcheck` if available) on every `.sh` file; run `preflight.sh`'s streaming tool-call check live against the AI Hub key; run `new-notebook.sh test-slug` end to end.
- [ ] Commit: `feat: workshop scripts`

### Task 5: Notebook template
**Files:** `notebooks/_template/notebook.py`, `notebooks/_template/metadata.json`, `notebooks/_template/public/.gitkeep`.
- [ ] `notebook.py`: PEP 723 header (pinned deps incl. `duckdb`), `marimo.App(width="full", app_title=...)`, `wasm_dependencies` async cell with the `pyodide`/`micropip` guard (verbatim pattern confirmed from `dashboards/notebooks/ori-data-quality/notebook.py`), `imports` cell, a worked query — count of Dutch institutions from `openalex.institutions` (confirmed table/column shapes from `agentic-tools/skills/ori-ducklake/references/schemas.md`) — producing a chart with zero edits, one commented-out stated-proxy example cell.
- [ ] `metadata.json`: `title`, `image`, `authors[]` (`name`/`github`/`orcid`), comments on which fields are required — matches `dashboards/notebooks/*/metadata.json` shape exactly.
- [ ] Verify: `uvx marimo check notebooks/_template/notebook.py` and `uvx marimo export html-wasm notebooks/_template/notebook.py -o /tmp/test.html` both succeed — **can run this now**, DuckLake catalog is reachable.
- [ ] Commit: `feat: notebook template`

### Task 6: `docs/ideas.md`
**Files:** `docs/ideas.md`.
- [ ] Standing note at top: aggregate-only for security/integrity/performance questions, framed as craft.
- [ ] 12 entries, 4 per tier, each: "I want to see X for Y, so that Z", source tables, 30-min scope, proxy caveat for tier 2/3 — **grounded in real schema fields** confirmed this session (`openalex.works.funders[]`/`.awards[]`/`.primary_topic`, `openalex.sources.issn_l`/`.is_in_doaj`, `openaire.publications.organizations[]`/`.projects[]`, `cris.publications`, `openapc.apc`), not invented column names.
- [ ] Include the two reference examples from the brief roughly as written.
- [ ] Commit: `docs: seed ideas.md`

### Task 7: Remaining docs — `AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/troubleshooting.md`, `docs/participant-quickstart.md`, `docs/rubric.md`
- [ ] Drop in the two supplied files (`participant-quickstart.md`, `rubric.md`) with the `npx skills add ... --agent claude-code --copy --yes` correction applied to the quickstart's Step 3.
- [ ] `AGENTS.md`: conventions, `.claude/skills/` rationale (cite the source-verified discovery behavior, not "per the docs"), Marimo-notebook-under-`notebooks/<slug>/` contract.
- [ ] `CLAUDE.md`: one line → `AGENTS.md`.
- [ ] `README.md`: two-minute promise, agent-agnostic framing, jurisdiction difference, `.claude/skills/` note.
- [ ] `docs/troubleshooting.md`: all symptoms from Phase 7, plus the exact `--agent claude-code --copy --yes` command and why (symlink/Windows).
- [ ] Commit: `docs: agent guidance and quickstart`

### Task 8: GitHub furniture — `PULL_REQUEST_TEMPLATE.md`, `ISSUE_TEMPLATE/workshop-idea.yml`
- [ ] PR template: question sentence, sources, proxy + what it misses, works/doesn't, rubric self-assessment, exit-ticket line.
- [ ] Issue template: phone-usable fallback capture.
- [ ] Commit: `chore: PR and issue templates`

### Task 9: CI — `.github/workflows/validate.yml`
- [ ] `uvx ruff check` + `uvx marimo check` on changed notebooks, advisory/non-blocking (`continue-on-error: true` or equivalent, no required status check).
- [ ] Verify: run the workflow's commands locally against the template notebook.
- [ ] Commit: `ci: advisory notebook validation`

### Task 10: Devcontainer — `.devcontainer/`
- [ ] Codespaces fallback: both agents installable, skills already vendored (same repo, no separate skill install path needed since `.claude/skills/` is already there).
- [ ] **Cannot launch/test actual Codespaces from this session** — state this plainly rather than claiming it works.
- [ ] Commit: `feat: devcontainer fallback`

## Final verification pass (per brief's "Verification before you call this done")

Run everything that's actually runnable from this sandbox: preflight streaming tool-call check against the live key, `marimo check`/`export html-wasm` on the template, script syntax checks, `git log -p | grep` for the leaked-key pattern, skills-lock hash generation. Explicitly report as **not run**: `sbx`-dependent checks (preflight full run, start.sh, submit.sh's `gh` PR flow against a real fork), Codespaces devcontainer launch, Windows/`preflight.ps1`, macOS. Do not claim these phases verified.

## Open decisions carried into the PR summary (per brief, not resolved here)

3b (who warms the model), 6 (repo visibility), 7 (PR target — recommend land in workshop repo first per brief's own recommendation), 9 (key rotation documentation), 10 (ideas.md review against Deliverable A1 — flagged, not resolvable from this session's available sources).
