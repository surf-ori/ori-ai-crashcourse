# Troubleshooting

Find your symptom, read the fix. If nothing here matches, paste the exact
error text into the shared channel or ask the facilitator — don't sit on
it silently.

---

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

**Preflight says the key was rejected**
Your `SURF_AIHUB_API_KEY` has either expired or was mistyped. Re-run
`sbx secret set SURF_AIHUB_API_KEY` and paste the key fresh from your
invitation email — no extra spaces or quotes. If it's still rejected after
that, the key has likely expired; check the date in your invitation email
and ask the facilitator for a new one.

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
`submit.sh` will still commit and push your branch, then print the exact
URL to open a PR by hand — use that. If pushing also fails, open the
"Workshop idea" issue template from your phone (GitHub → Issues → New
issue) and paste your notebook contents in. Your idea gets captured either
way.

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
