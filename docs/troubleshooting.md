# Troubleshooting

Find your symptom, read the fix. If nothing here matches, paste the exact
error text into the shared channel or ask the facilitator — don't sit on
it silently.

---

**The agent looks frozen the first time you ask a data question — no
response, no error, nothing**
Normal. The `ori-ducklake` skill fetches and installs its MCP server fresh
inside your sandbox the first time it's used, and that setup (a `git`
fetch plus a Python environment install) prints nothing while it runs — it
can take a few minutes, sometimes longer on a slow connection. This is a
**per-sandbox** cost: unlike the AI Hub model warm-up, the facilitator
cannot pre-warm this for you, since it happens inside your own sandbox, not
a shared backend. It only happens once per sandbox — wait it out rather
than restarting, since restarting just means paying the cost again. If it's
genuinely still nothing after 5+ minutes, that's worth flagging to the
facilitator rather than continuing to wait.

**`git clone`/`git fetch`/`git push` inside the sandbox fails with `fatal:
could not read Username for 'https://github.com': terminal prompts
disabled`**
This happens even cloning a genuinely public repo — it's not about
permissions on that specific repo. The sandbox's network proxy needs a
`github` secret configured before *any* git-over-HTTPS traffic works at
all, and nothing sets one up by default. Fix:

```bash
sbx secret set github
```

Paste a GitHub personal access token (classic, `repo` scope — create one at
https://github.com/settings/tokens/new) when prompted. This is needed for
two things in this workshop: the `ori-ducklake` skill fetching its MCP
server from GitHub the first time you use it, and `submit.sh`'s `git push`
at the end. `./scripts/preflight.sh` checks for this now ("git can reach
GitHub from inside the sandbox") — if you see it fail there, this is the
fix, before you even start building.

**On Windows, running `./scripts/preflight.sh` pops up "How do you want to
open this file?"**
You're typing the command into PowerShell or cmd — neither can run bash
scripts, so Windows falls back to asking which app should open the `.sh`
file. Install [Git for Windows](https://git-scm.com/downloads/win) if you
haven't, then open a **Git Bash** window specifically (Start menu → "Git
Bash", or right-click the repo folder in File Explorer → "Git Bash Here")
and run the command there instead. `preflight.ps1` is the only script with a
PowerShell equivalent — `start.sh`, `submit.sh`, and `new-notebook.sh` need
Git Bash (or WSL2).

**Ctrl-C to copy the agent's reply quit the whole session instead**
Don't use Ctrl-C inside the agent — it's the terminal interrupt signal, and
it looks like it kills the sandbox attach (`sbx run`) rather than just
canceling whatever the agent is doing. To copy text, use your terminal's own
selection instead of a keyboard shortcut: in **Git Bash (mintty)**, just
select text with your mouse — it copies to the clipboard automatically, no
Ctrl-C needed. If you do get dropped out, run `sbx ls` to find your
sandbox's name, then `./scripts/start.sh <agent>` again (or
`sbx run --name <name>`) to reattach — with luck your conversation is still
there; if not, check `opencode --help` / `claude --help` inside the sandbox
for the real resume-session flag rather than guessing one.

**`sbx` says my hardware isn't supported / won't install**
Docker Sandboxes needs macOS on Apple Silicon, Linux x86_64 with KVM, or
Windows 11 x86_64. Intel Macs and locked-down managed Windows laptops will
fail here — this is expected, not something to debug further. Use the
Codespaces fallback instead: open this repo at
`https://github.com/codespaces` (or click "Code" → "Codespaces" → "Create
codespace" on GitHub). Same repo, same skills, same agents, no local
install.

**`sbx login` loops back to the browser / never finishes**
Close the browser tab, run `sbx login` again from a fresh terminal. If it
loops a second time, check you're not behind a proxy that blocks
`docker.com` — if you are, use the Codespaces fallback instead of fighting
the proxy.

**Preflight says the key was rejected, or `SURF_AIHUB_API_KEY` never shows up
inside the sandbox**
Your `SURF_AIHUB_API_KEY` has either expired, was mistyped, or was set with
the wrong `sbx` subcommand. This key uses **`sbx secret set-custom`**, not
plain `sbx secret set` — the SURF AI Hub isn't one of Docker's built-in
providers (`anthropic`, `github`, `openai`, etc.), so the proxy needs an
explicit host to match against. If you ever ran `sbx secret set
SURF_AIHUB_API_KEY` (without `-custom`), that secret is a dead end: it's
stored, but nothing ever delivers it into a sandbox or matches it to any
outbound request. Clear it out and redo it correctly:

```bash
sbx secret rm SURF_AIHUB_API_KEY
sbx secret set-custom --host willma.surf.nl --env SURF_AIHUB_API_KEY
```

Paste the key fresh from your invitation email — no extra spaces or quotes.
If it's still rejected after that, the key has likely expired; check the
date in your invitation email and ask the facilitator for a new one.

**`sbx secret set-custom` shows nothing when I paste — did it work?**
Yes, that's expected: the "Enter secret:" prompt masks input completely, no
`*` and no cursor movement. It should then print something like `Saved
custom secret placeholder "sbx-cs-..." for target "willma.surf.nl" env
"SURF_AIHUB_API_KEY"`. If you want to confirm before running preflight, run
`sbx secret ls` and look for a `SURF_AIHUB_API_KEY` row — that's
non-destructive, unlike re-running `set-custom`, which would generate a new
placeholder and require restarting any sandbox you already have open. The
authoritative check either way is `./scripts/preflight.sh` — it fails
outright on a missing or bad key.

**In a Codespace, a call to `willma.surf.nl` returns curl exit code `000`**
`000` means curl never got a response at all — not an auth failure, a
connection failure. This can happen if your GitHub organization runs a
Codespaces network firewall/allowlist that blocks egress to hosts outside a
default list, and `willma.surf.nl` isn't on it. This is **not yet confirmed
as the cause** — it could also be a transient network issue or a cold model
needing longer than curl's default wait. If you hit this, tell the
facilitator with the exact command and output; it may need your GitHub org
admin to add `willma.surf.nl` to the Codespaces allowlist, which is outside
what you can fix from inside the Codespace.

**Preflight says the model isn't responding, or lists it as unavailable**
The model may not be enabled on your collaboration's AI Hub key, or the
collaboration's model list changed since this repo was built. Tell the
facilitator — this needs a change on the AI Hub side, not on your laptop.

**Preflight fails "model can use tools (streaming)" — this is the check
that matters most**
Don't just retry. This means the configured model cannot hold up its end
of an agentic conversation over a streaming connection, which is how both
OpenCode and Claude Code actually talk to it. Retrying won't fix a model
that structurally can't stream tool calls. Contact the facilitator.

**Model takes two to four minutes to answer the first time**
Normal. On-demand models spin up on first use — this can take up to four
minutes. Preflight will warn you about this ("model was cold") rather than
fail. Run preflight a second time and it should answer in a couple of
seconds. If a *second* run is still slow, something is actually wrong —
then say so.

**A query against `openalex.works` hangs or times out**
Expected on an unfiltered or lightly filtered query — it's 364 million
rows. Filter first (by institution, DOI, or year), aggregate second. Never
`UNNEST` authorships across the full table without a `WHERE` first. Ask
your agent to run `DESCRIBE` on the table before writing a query against
an unfamiliar column, rather than guessing a name.

**`uvx marimo export html-wasm` fails**
Common under time pressure and forgivable — ship the notebook anyway and
say so honestly in the PR description ("WASM export fails" is useful
information, not a confession). If you want to chase it: check the
`wasm-compatibility` skill, and run
`uvx marimo check notebook.py --select MW --format json` to see which
import or package is the problem.

**`gh` isn't authenticated, so `submit.sh` can't open a PR**
Expected in the sbx sandbox lane — the sandbox's proxy authenticates raw
`git` HTTPS traffic (clone/push) transparently, but not `gh` CLI's own
separate API login, so `gh pr create` will not fire there. (Codespaces is
different: `gh` comes pre-authenticated automatically, so this step usually
does work there.) Either way, `submit.sh` still commits and pushes your
branch, then prints the exact URL to open a PR by hand against the upstream
repo (`surf-ori/ori-ai-crashcourse`, not your fork) — use that. If pushing
also fails, open the "Workshop idea" issue template from your phone (GitHub
→ Issues → New issue) and paste your notebook contents in. Your idea gets
captured either way.

**Skills aren't showing up when you type `/skills`**
Check `.claude/skills/` in the repo root — that's the one place both
OpenCode and Claude Code read skills from in this repo. If it's empty or
missing, your clone is incomplete; re-clone rather than trying to patch it
by hand. If `.claude/skills/` looks fine but your agent still doesn't see
them, check you're running the agent from inside the repo directory (skill
discovery is relative to your working directory).

**`npx skills add` for a new skill lands somewhere your agent doesn't
read**
Always pass all three flags:

```bash
npx skills add <owner>/<repo> --agent claude-code --copy --yes
```

`--agent claude-code` targets `.claude/skills/`, the one directory both
agents in this repo read. `--copy` writes a real file instead of a
symlink — symlinks silently fail on Windows without developer mode
enabled, which most participants won't have. Without both flags, a bare
`npx skills add owner/repo --yes` may symlink into `.agents/skills/`
instead (or in addition), which OpenCode also reads but Claude Code does
not — so the skill would work for one agent lane and silently not the
other.
