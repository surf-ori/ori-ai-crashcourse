# Agent Build Brief
## Build `surf-ori/ori-ai-crashcourse`

Hand this to Claude Code as the spec. Read it fully before writing anything, then work through the phases in order, committing per concern.

---

## Mission

A workshop repository that a non-technical participant clones, runs one script in, and is immediately talking to a capable AI coding agent with every relevant skill already loaded. Zero skill installation, zero API wiring, zero Node troubleshooting during the session.

The participant produces a Marimo notebook that lands as a pull request against `surf-ori/dashboards`.

**Two design constraints, in priority order:**

1. **Under two minutes from `git clone` to a working agent.** Every decision defers to this. If a step could fail on a stranger's laptop, remove it or make the failure loud and self-diagnosing.
2. **Agent-agnostic.** It must work identically for a participant running OpenCode and one running Claude Code. Neither is a second-class path.

---

## Reference material

Read these before starting. Most of what you need already exists.

| Source | Take from it |
|---|---|
| `surf-ori/dashboards` | `opencode.json`, `skills-lock.json`, `AGENTS.md`, `CLAUDE.md`, `notebooks/*/` layout, `.github/scripts/build.py`, `.github/workflows/deploy.yml` |
| `surf-ori/ducklake-overview` | `.agents/skills/` (superpowers + ponytail already vendored), `skills-lock.json` |
| `surf-ori/agentic-tools` | `skills/ori-ducklake`, `skills/oai-pmh`, `skills/urn-nbn`; `mcp-servers/ori-ducklake-mcp` |

Do not re-derive conventions these repos already establish. Copy them.

---

## Phase 1: Skeleton

```
ori-ai-crashcourse/
├── README.md
├── AGENTS.md
├── CLAUDE.md                       # one line, points at AGENTS.md
├── opencode.json
├── .mcp.json                       # Claude Code MCP config
├── skills-lock.json
├── .gitignore
├── .claude/skills/                 # vendored, see Phase 2
├── .devcontainer/                  # Codespaces fallback, see Phase 7
├── scripts/
│   ├── preflight.sh
│   ├── preflight.ps1
│   ├── start.sh
│   ├── new-notebook.sh
│   └── submit.sh
├── notebooks/
│   └── _template/
│       ├── notebook.py
│       ├── metadata.json
│       └── public/.gitkeep
├── docs/
│   ├── participant-quickstart.md
│   ├── ideas.md
│   ├── rubric.md
│   └── troubleshooting.md
└── .github/
    ├── ISSUE_TEMPLATE/workshop-idea.yml
    ├── PULL_REQUEST_TEMPLATE.md
    └── workflows/validate.yml
```

`.gitignore` must include `.env`, `*.key`, `.opencode/auth.json`, `.claude/settings.local.json` and anything else that could carry a credential. First commit, before anything else exists.

---

## Phase 2: Vendor the skills, once, for both agents

**Vendor into `.claude/skills/`.** This is a deliberate change from the sibling repos, which use `.agents/skills/`.

Reason: Claude Code discovers `.claude/skills/<name>/SKILL.md`. OpenCode discovers `.opencode/skills/`, `.claude/skills/` *and* `.agents/skills/`. So `.claude/skills/` is the only single location both agents read. One copy, no symlinks (which break on Windows without developer mode), no duplication to drift.

Note this choice in the repo `README.md` and in `AGENTS.md` so nobody "fixes" it back later.

If `npx skills add` defaults to writing `.agents/skills/`, either pass its target flag or normalise afterwards. Whichever you choose, document the exact command in `docs/troubleshooting.md`, because participants will run `npx skills add` for `ponytail` during the session and the skill must land where their agent looks.

**Vendor, do not fetch at runtime.** A participant behind an institutional proxy with no working npm must still get every skill.

| Source repo | Skills |
|---|---|
| `obra/superpowers` | `using-superpowers`, `brainstorming`, `writing-plans`, `executing-plans`, `test-driven-development`, `verification-before-completion`, `systematic-debugging`, `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `finishing-a-development-branch`, `writing-skills` |
| `DietrichGebert/ponytail` | `ponytail`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help`, `ponytail-review` |
| `surf-ori/agentic-tools` | `ori-ducklake`, `oai-pmh`, `urn-nbn` |
| `marimo-team/skills` | `marimo-notebook`, `wasm-compatibility`, `anywidget` |
| `davila7/claude-code-templates` | `polars` |

Write `skills-lock.json` in the shape used by the sibling repos: `source`, `sourceType`, `skillPath`, `computedHash`. Generate it with `npx skills` rather than by hand so the hashes are real.

**Trim aggressively.** Every skill description sits in the agent's context. I have already dropped `dispatching-parallel-agents` and `subagent-driven-development` from the list above; neither fires in a solo 60-minute notebook build. Cut further if the list still feels long, and justify the final set in the PR summary.

`ponytail` is vendored *and* is the one participants install by hand as a teaching exercise. Reinstalling over the vendored copy is harmless; say so in the docs so nobody panics at the "already exists" message.

---

## Phase 3: Model access, both lanes

### OpenCode lane (default): SURF AI Hub

**All of the following was verified against a live workshop key on 19 August 2026.** Do not re-derive it; do re-run the model checks if the collaboration's enabled model list changes.

Base URL `https://willma.surf.nl/api/v0`, OpenAI-compatible at `/chat/completions`. Confirmed: `/api/v0/chat/completions` → 200; `/api/v0/v1/chat/completions` → 404. Do not add a `/v1` suffix.

Auth: **both** `X-API-KEY: <key>` and `Authorization: Bearer <key>` return 200. No custom header block is needed; OpenCode's standard `apiKey` option is sufficient.

#### Model selection: tool calling tested, seven models

| Model | Tools (non-stream) | Tools (streaming) | Cold start | Verdict |
|---|---|---|---|---|
| `Sehyo/Qwen3.5-122B-A10B-NVFP4` | ✅ | ✅ | ~2s warm | **Primary** |
| `RedHatAI/gemma-4-31B-it-NVFP4` | ✅ | ✅ | 131s cold | **Fallback** |
| `mistralai/Devstral-Small-2-24B-Instruct-2512` | ✅ | ✅ | **264s cold** | Works, cold start too slow for a workshop |
| `openai/gpt-oss-120b` | ✅ | ❌ **returns `data: [DONE]` immediately, no content** | always-on | **Unusable in OpenCode** |
| `default-text-large` | ✅ | ❌ | always-on | Alias for `openai/gpt-oss-120b`; same defect |
| `Qwen/Qwen2.5-Coder-32B-Instruct-AWQ` | ❌ emits `<tools>{...}</tools>` as plain text | — | 71s | Unusable, broken tool parsing |
| `Qwen/Qwen2.5-VL-32B-Instruct-AWQ` | ❌ answers in prose | — | — | Unusable |
| `Qwen/Qwen3-Embedding-8B` | n/a | n/a | — | Embedder |

**The trap to avoid:** `openai/gpt-oss-120b` and its alias `default-text-large` are the two always-on models, they pass a naive non-streaming tool test, and they are the obvious default choice. But OpenCode streams, and with `stream: true` plus a `tools` array they return a bare `data: [DONE]` and nothing else. Reproduced three times. A preflight check that does not stream will pass and the workshop will still fail. **Preflight check 6 must use `stream: true`.**

Full agentic round trip verified on the primary and fallback: tool call issued, tool result fed back as a `tool` role message, correct natural-language answer returned. Two turns, ~3s total warm.

Context: `Sehyo/Qwen3.5-122B-A10B-NVFP4` accepted a 260,000-token prompt without error; gemma accepted 130,000. Set conservative limits in config rather than advertising the ceiling.

#### Cold start is an operational risk, not a config problem

Every tool-capable model is `on-demand` and reports `state: unloaded` when idle, **including models the back office UI shows as "Running"**. The UI status is not reliable; trust `GET /models`.

A cold on-demand model took 131 to 264 seconds to answer. If twelve participants hit a cold model at 0:07, the sync point collapses.

**Add to the facilitator checklist, and to `scripts/preflight.sh` as a warning:** send one throwaway completion to the configured model 10 to 15 minutes before the session starts, and again if the room has been idle. Cheap, and it converts a 4-minute stall into a 2-second response.

#### Verified config

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "surf-aihub": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "SURF AI Hub",
      "options": {
        "baseURL": "https://willma.surf.nl/api/v0",
        "apiKey": "{env:SURF_AIHUB_API_KEY}"
      },
      "models": {
        "Sehyo/Qwen3.5-122B-A10B-NVFP4": {
          "name": "Qwen3.5 122B (SURF)",
          "limit": { "context": 128000, "output": 8192 }
        },
        "RedHatAI/gemma-4-31B-it-NVFP4": {
          "name": "Gemma 4 31B (SURF)",
          "limit": { "context": 64000, "output": 8192 }
        }
      }
    }
  }
}
```

Set `Sehyo/Qwen3.5-122B-A10B-NVFP4` as the default model. Do **not** list `openai/gpt-oss-120b`, `default-text-large` or either Qwen2.5 model; leaving them selectable is a live trap for a participant who idly switches models mid-session.

`surf-ori/dashboards` currently uses provider key `lmstudio`. Rename to `surf-aihub`; the old name is a leftover and confuses participants.

### Claude Code lane

Claude Code cannot use the AI Hub key: the AI Hub is OpenAI-shaped and Claude Code expects the Anthropic API. A proxy would bridge it and is **out of scope**; do not build one.

So: Claude Code users bring their own subscription. What the repo must provide for them:

- `.mcp.json` with the `ori-ducklake` MCP server in Claude Code's format, mirroring the OpenCode MCP block
- `CLAUDE.md` containing a single line pointing at `AGENTS.md`, so conventions live in one file
- Skills already covered by the `.claude/skills/` decision above

Document the jurisdiction difference plainly in `README.md` and `docs/participant-quickstart.md`: same skills, same notebook, different jurisdiction. Do not bury it.

### MCP server, both lanes

`uvx --from git+https://github.com/surf-ori/agentic-tools ...` with
`DUCKLAKE_URL=https://objectstore.surf.nl/cea01a7216d64348b7e51e5f3fc1901d:sprouts/catalog.ducklake`.

Prefer the zero-clone `uvx` route over the hosted instance so it survives after the session.

---

## Phase 4: Scripts

Every script: `set -euo pipefail`, plain-language errors, no jargon in user-facing output. Assume the reader has never seen a stack trace and will read only the last line.

**`preflight.sh` / `preflight.ps1`** — one ✅/❌ line per check, non-zero exit on any failure:

1. `sbx` on PATH and logged in
2. A sandbox starts
3. Agent choice detected or asked
4. Credentials present for the chosen lane (`SURF_AIHUB_API_KEY` secret, or Claude Code auth)
5. Model responds to a trivial completion
6. **Model completes a tool call over a streaming request.** Must send `stream: true` together with a `tools` array. A non-streaming tool test passes on models that are broken in OpenCode; see the model table above.
7. Skills load, count matches expectations
8. `git` present, `github.com` reachable

Check 6 is the one that matters, and it must stream. If the model cannot stream tool calls, the agent loop is unusable and the session collapses at minute five. Make that failure unmissable and tell the reader to contact the facilitator, not to retry.

Add check 9: **warn if the model was cold.** If the first completion takes over 20 seconds, print a note explaining that on-demand models spin up on first use and that a second run should be fast. Without this, participants will read a normal cold start as a broken setup.

End with a copyable summary block the participant can screenshot.

**`start.sh`** — asks which agent (default OpenCode, remembers the choice), then `sbx run opencode` or `sbx run claude` in the repo directory. Runs preflight quietly first; on failure, print the failing line and stop rather than dropping the participant into a broken session. Print a two-line "you are in the sandbox, type /skills" banner.

**`new-notebook.sh <slug>`** — copies `notebooks/_template/` to `notebooks/<slug>/`, substitutes the title, validates the slug is lowercase-hyphenated.

**`submit.sh`** — highest-risk script, because it runs at minute 55 when everyone is tired:

- Detect the notebook directory; if ambiguous, ask rather than guess
- Branch `notebook/<github-handle>-<slug>`
- **Scan the diff for anything resembling a credential and abort loudly if found**
- Commit, push, open a PR via `gh`
- If `gh` is missing or unauthenticated, print the exact URL to open the PR by hand. Never fail silently.

---

## Phase 5: Notebook template

Mirror `surf-ori/dashboards` exactly so submissions merge cleanly.

`notebook.py`: PEP 723 script header with pinned dependencies, `marimo.App(width="full", app_title=...)`, a `wasm_dependencies` cell with the `micropip` guard, an `imports` cell, then a clearly marked "your work starts here" cell with a worked DuckLake query already in it.

**The template must produce a chart on first run with zero edits.** Someone who sees output in ten seconds engages differently from someone staring at an empty notebook. Use something small and fast, for example a count of Dutch institutions from `openalex.institutions`. Do not touch `openalex.works` unfiltered in the template.

Include one commented-out cell showing a **stated proxy**: a measure with a one-line note saying what it stands in for and what it misses. Strategic questions live or die on this habit and the template is the cheapest place to teach it.

`metadata.json`: `title`, `image`, `authors[]` with `name`, `github`, `orcid`. Comment which fields are required.

---

## Phase 6: `docs/ideas.md`

**Twelve seeded questions, four per tier.** This file does more work than any other doc: it sets the room's sense of what counts as a legitimate question. If every entry is metadata plumbing, every submission will be metadata plumbing.

Each entry: one sentence in "I want to see X for Y, so that Z" form, the source tables it would touch, a realistic 30-minute scope, and for the strategic ones, **an explicit note on what the proxy is and what it misses**.

**Tier 1 — Operational (the data itself).** Publications missing a ROR in one source but not another. Funder DOI coverage per institution. ISSN harmonisation gaps. OA status disagreement between OpenAlex and the CRIS.

**Tier 2 — Strategic (the research portfolio).** Grant funding for SDG-related projects over time. Industry co-authorship by faculty. APC spend against open access share. Diamond OA journal uptake by discipline.

**Tier 3 — Leadership and policy.** International co-publication partners by country over time, as a factual base for a knowledge security conversation. Open access share benchmarked against other Dutch universities. Research portfolio concentration by topic against strategic priorities. Grant success profile by funder programme.

Reference examples to include roughly as written, because they came from the facilitator and set the right altitude:

> "Plot over time how much funding my institution won for SDG-related projects and publications."
> *Touches: OpenAIRE projects, OpenAlex topics. Proxy: topic classification stands in for SDG alignment; it will miss projects whose SDG relevance is not visible in the abstract, and over-count generic environmental topics. Say so in the notebook.*

> "Build a knowledge security overview of past research collaborations for university leadership."
> *Touches: OpenAlex works and institutions, co-authorship affiliations. Scope to: co-authored outputs per partner country per year. Aggregate only.*

**Add a short standing note at the top of the file:** for knowledge security, integrity and performance questions, keep the unit of analysis aggregate (institution, country, faculty, year), never a named researcher. These notebooks go into a public repository. Frame it as craft, not as a rule, and give the reason.

---

## Phase 7: GitHub furniture and fallback

- `docs/participant-quickstart.md` and `docs/rubric.md`: use the supplied files.
- `docs/troubleshooting.md`: symptom to fix, written for someone panicking. Cover at minimum: `sbx` unsupported hardware, Docker login loop, key rejected, model not enabled, tool calling unsupported, query timeout on large tables, WASM export failure, `gh` not authenticated, skills not appearing (and which directory to check for which agent).
- `AGENTS.md`: repository conventions, the `.claude/skills/` rationale, and an explicit statement that the deliverable is a Marimo notebook under `notebooks/<slug>/` following the `surf-ori/dashboards` contract. This is what steers the agent to the right artifact, so be direct.
- `CLAUDE.md`: one line pointing at `AGENTS.md`.
- `PULL_REQUEST_TEMPLATE.md`: question in one sentence, data sources, **any proxy used and what it misses**, what works, what does not, self-assessment against the rubric, and the exit-ticket line ("the number I trusted least was \_\_\_ because \_\_\_").
- `ISSUE_TEMPLATE/workshop-idea.yml`: fallback capture when `gh` fails. Must be usable from a phone.
- `.github/workflows/validate.yml`: on PR, `uvx ruff check` and `uvx marimo check` on changed notebooks. **Advisory, non-blocking.** A red X on a beginner's first pull request is a bad teaching moment.
- `.devcontainer/`: Codespaces fallback for participants whose hardware cannot run `sbx`. Same repo, same skills, both agents. Treat this as required, not optional; roughly 10 to 25 percent of the audience will need it.

---

## Verification before you call this done

Do not report success on any of these without having run them.

1. Fresh clone into a clean directory, `./scripts/preflight.sh`, all green.
2. `./scripts/start.sh` → OpenCode. `/skills` lists the expected skills, no load errors.
3. `./scripts/start.sh` → Claude Code. Same skill list. **Both lanes, explicitly.**
4. End to end as a participant, once from Tier 1 and once from Tier 3 of `ideas.md`, through to an opened PR. The strategic one is the real test of whether the skills and template help.
5. `uvx marimo export html-wasm` on the template succeeds.
6. Codespaces devcontainer launches and reaches a working agent.
7. `git log -p | grep -iE 'api[_-]?key|secret|token|77696c6c6d61'` finds nothing.
8. Test on macOS and Linux if you can. State explicitly what you could not test.

---

## Open decisions to flag in the PR summary

Do not silently resolve these. List them with your recommendation.

1. ~~**Model ID and tool-calling support.**~~ **Resolved and tested.** See the model table in Phase 3. Primary `Sehyo/Qwen3.5-122B-A10B-NVFP4`, fallback `RedHatAI/gemma-4-31B-it-NVFP4`. Re-run the streaming tool test if the collaboration's enabled models change before the session.
2. ~~**Auth header.**~~ **Resolved.** Both `X-API-KEY` and `Authorization: Bearer` work. Use OpenCode's standard `apiKey` option; no custom headers.
3. ~~**Endpoint shape.**~~ **Resolved.** `https://willma.surf.nl/api/v0` + `/chat/completions`. No `/v1` suffix.
3b. **Model warming.** Decide who sends the warm-up request before the session and whether preflight should do it automatically for participants running early.
4. **Skills directory.** Confirm `.claude/skills/` is picked up by the current OpenCode version in practice, not just per the docs. If not, fall back to duplicating into `.agents/skills/` and add a sync check to preflight.
5. **`npx skills add` target.** Which directory it writes to by default, and the exact command participants should run so `ponytail` lands where their agent looks. Different for the two lanes if the flag is agent-specific.
6. **Repository visibility and access.** Public with forks, or private with participants added? Affects `submit.sh` materially.
7. **PR target.** Straight to `surf-ori/dashboards`, or land in the workshop repo first and cherry-pick? Recommend the latter: keeps the production repo clean and lets Maurice curate.
8. **Skill count.** Final list after trimming, with reasoning.
9. **Key rotation.** Where the expiry date is documented and what participants are told to do afterward.
10. **Ideas file review.** The strategic and leadership entries are drafted from general ORI knowledge, not from the PID to Portal use case inventory. Worth a pass against Deliverable A1 before the session so the questions match what institutions actually said they need.

Commit separately per concern: skeleton, skills, provider config, scripts, template, ideas, docs, CI, devcontainer. Till reviews these, so keep the diffs readable.
