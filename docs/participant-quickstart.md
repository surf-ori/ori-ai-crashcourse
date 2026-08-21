# Participant Quickstart
## ORI Crash Course: Coding with AI

You will build a small data dashboard about Dutch open research information, in one hour, without writing code yourself. You will direct an AI agent that writes it for you, and you will judge whether what it produced is any good.

The question you bring can be operational ("how many of our publications are missing a ROR?") or strategic ("how much grant funding did we win for SDG-related work, over time?"). Both are welcome. The strategic ones are usually harder and more interesting.

Everything runs on your own laptop and keeps working after the session.

---

# Part 1: Before the session (do this now, takes about 20 minutes)

Do this at least a few days ahead. If it does not work, you have time to ask. If you leave it to the morning of, you will spend the workshop watching other people build things.

## What you need

- A laptop you can install software on
- A GitHub account ([sign up free](https://github.com/signup))
- A Docker account ([sign up free](https://app.docker.com/signup)) — `sbx login` in Step 1 needs one to authenticate the sandbox. Docker's sign-up page usually offers a "Continue with GitHub" button; if you see it, use that and you won't need a second password.
- The API key sent to you by email. It expires on the date in that email.

## Which AI agent?

Two options. The repository works with both, and every skill is pre-loaded for both.

**OpenCode (default).** Uses the SURF AI Hub key you were sent, running Qwen3.5 122B on SURF hardware. Your prompts and data stay on Dutch infrastructure, under your institution's contract. Choose this unless you have a reason not to.

**Claude Code.** If you already use it and have your own subscription, keep using it. Everything in the repository works unchanged: same skills, same notebook template, same submission.

One honest difference: Claude Code cannot use the SURF AI Hub key, so it runs on Anthropic's own service. Your prompts and any data you paste leave the Netherlands. Same skills, same notebook, different jurisdiction. Worth knowing before you choose.

The startup script asks which one you want.

**Check your laptop is supported.** Docker Sandboxes needs one of:

- macOS on Apple Silicon (M1 or newer; not Intel Macs)
- Linux x86_64 with KVM
- Windows 11 x86_64

Not sure? Run step 1 and see what happens. If it fails, reply to the invitation email and you will be put in the browser-based lane, which needs no install at all. That is a normal outcome, not a problem.

## Step 1: Install the sandbox

The sandbox is a disposable mini-computer on your laptop. The AI agent runs inside it, so it can see the workshop folder and nothing else. Not your documents, not your passwords.

**macOS:**
```bash
brew install docker/tap/sbx
sbx login
```

**Linux:**
```bash
curl -fsSL https://get.docker.com | sudo REPO_ONLY=1 sh
sudo apt-get install docker-sbx
sudo usermod -aG kvm $USER
newgrp kvm
sbx login
```

**Windows 11:** this takes about five steps. Go slowly and do each one in
order — most workshop participants are on Windows and have never used a
command line before, so nothing here is assumed.

1. Press the **Windows key + S** to open search, type `powershell`, and
   look at the result named "Windows PowerShell".
2. Right-click it and choose **"Run as administrator"**. Click **Yes** on
   the prompt that follows.
3. **If "Run as administrator" is greyed out, or you don't have an admin
   password to enter** — your laptop is managed by your institution's IT
   and you cannot install software on it. Stop here and use the
   browser-based Codespaces fallback instead: open
   https://github.com/codespaces and click "Code" → "Codespaces" → "Create
   codespace" on the workshop repo (see
   [`docs/troubleshooting.md`](troubleshooting.md) for details, under
   "`sbx` says my hardware isn't supported"). That path needs no admin
   rights and no local install at all.
4. In the blue admin PowerShell window that opened, type each of these
   three lines **one at a time**, pressing Enter after each and waiting for
   it to finish before typing the next:

   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All
   ```

   ```powershell
   winget install -h Docker.sbx
   ```

   ```powershell
   sbx login
   ```

   If Windows asks you to restart the computer after the first command, do
   so, then reopen an admin PowerShell window (steps 1 to 2) and continue
   from the `winget install` line.

   `sbx login` opens your browser and asks you to sign in with the Docker
   account from [What you need](#what-you-need) above. It is free and
   happens once. When it asks about a network policy, choose **Open** for
   this workshop.

5. Close the admin PowerShell window — you won't need admin rights again.
   Every remaining command in this guide runs in an ordinary, non-admin
   window called **Git Bash**, which you install next.

**Every script in this repo is a bash script, not a PowerShell script —
this is not optional.** `preflight.sh`, `start.sh`, `submit.sh`, and
`new-notebook.sh` cannot run in PowerShell or cmd. If you type
`./scripts/preflight.sh` into PowerShell, Windows will pop up a "How do you
want to open this file?" dialog instead of running it — that dialog means
you're in the wrong shell, not that anything is broken.

**Install Git Bash:**

1. Go to https://git-scm.com/downloads/win and download the installer (it
   auto-detects 64-bit).
2. Run the downloaded `.exe`. Click "Next" through every screen, keeping
   the defaults — you do not need to change any option. Click "Install",
   then "Finish".
3. From now on, whenever this guide says to run a command, open **Git
   Bash** specifically — not PowerShell, not cmd. Two ways to open it:
   - Press **Windows key + S**, type `git bash`, and open it, or
   - In File Explorer, open the `ori-ai-crashcourse` folder (once you have
     it — see Step 2 below), right-click inside it, and choose **"Git Bash
     Here"**.

   A PowerShell port exists only for `preflight.ps1`; the other three
   scripts have no PowerShell equivalent, so Git Bash is the one shell that
   gets you through the whole workshop.

## Step 2: Fork and clone the workshop repository

Go to https://github.com/surf-ori/ori-ai-crashcourse and click **Fork**
(top right) — this makes your own copy under your GitHub account. You'll
push your notebook there at the end and open a pull request from it; you
don't have write access to the shared repo directly.

Then clone **your fork** (replace `YOUR-USERNAME`):

```bash
git clone https://github.com/YOUR-USERNAME/ori-ai-crashcourse.git
cd ori-ai-crashcourse
```

Everything is already in there: the skills, the settings, the notebook template. You do not need to install skills one by one.

## Step 3: Add your credentials

**A GitHub token, first.** The sandbox's network proxy needs one to let *any*
`git` command reach `github.com` from inside the sandbox — even a plain
`git clone` of a public repo fails without it. You'll need this both for the
`ori-ducklake` data skill (which fetches its MCP server from GitHub the
first time you use it) and for `submit.sh`'s `git push` at the end.

Create a token at https://github.com/settings/tokens/new — classic token,
**`repo`** scope is enough (that's what lets you push to your own fork).
Then:

```bash
sbx secret set github
```

Paste the token when prompted (same silent-input behavior as below — nothing
echoes back, that's normal).

**Then your AI Hub key:**

```bash
sbx secret set-custom --host willma.surf.nl --env SURF_AIHUB_API_KEY
```

This is a **custom** secret (`set-custom`, not `set`) because the SURF AI Hub
isn't one of Docker's built-in providers. `--host willma.surf.nl` tells the
sandbox's network proxy which outbound requests should get your key attached;
`--env SURF_AIHUB_API_KEY` is the variable name `opencode.json` expects to
find it under.

Paste the key when prompted. **You won't see anything happen** — no `*`, no cursor
movement, nothing echoed back. That's the terminal masking your input, not a
frozen prompt. Paste (or type) the key and press Enter. You'll then see
something like:

```
Enter secret:
Saved custom secret placeholder "sbx-cs-xxxxxxxxxxxxxxxx" for target "willma.surf.nl" env "SURF_AIHUB_API_KEY" in scope "(global)"
```

That "placeholder" string is expected and correct — it's *not* your real key.
Inside a sandbox, `$SURF_AIHUB_API_KEY` holds this placeholder; the proxy
swaps it for your real key only on outbound requests to `willma.surf.nl`. The
real key is never exposed inside the sandbox itself.

Not sure it registered? `sbx secret ls` lists it non-destructively — look for
a `SURF_AIHUB_API_KEY` row. The real check either way is
`./scripts/preflight.sh` in the next step, which fails outright on a missing
or bad key.

It is stored by the sandbox, not in the repository.

**Never paste this key into a file inside the repository.** If you commit it by accident, tell the facilitator immediately so it can be revoked.

## Step 4: Run the check

```bash
./scripts/preflight.sh
```

You want to see all green:

```
✅ sbx installed and logged in
✅ sandbox starts
✅ SURF AI Hub key found
✅ model responds
✅ model can use tools (streaming)
✅ skills loaded (26)
✅ git and GitHub reachable
```

**Reply to the invitation email with a screenshot of this output.** That is your ticket in.

**If the model check takes two to four minutes, that is normal.** The model is loaded on demand and has to start up. Run the check a second time and it should answer in a couple of seconds. Only worry if it fails outright.

If anything is ❌, check [`docs/troubleshooting.md`](troubleshooting.md) first, then reply with the error text. Do not silently give up; there is a browser fallback that always works.

---

# Part 2: The session

## What you are making

A **Marimo notebook**. It is a Python file that behaves like a small interactive web page: charts, filters, tables. The workshop repository can turn it into a page anyone can open in a browser, with no install.

Real examples: https://surf-ori.github.io/dashboards/

## Step 1: Start

```bash
cd ori-ai-crashcourse
./scripts/start.sh
```

The script asks which agent you want. You are then inside the sandbox, talking to it. Type `/skills` to see what your agent already knows how to do.

**The first time you ask a data question, expect a silent wait of up to a
few minutes** — the `ori-ducklake` skill sets up its connection to the data
catalog fresh in your sandbox, and it doesn't print anything while that's
happening. This looks exactly like a freeze but isn't. It only happens
once; after that first connection, it's fast for the rest of the session.

## Step 2: Decide what you want to see

Write one sentence first, in your own words, before you type anything at the agent:

> "I want to see \_\_\_\_\_\_ for \_\_\_\_\_\_, so that \_\_\_\_\_\_."

The "so that" is what turns a topic into a question. Examples across the range:

*Operational, about the data itself:*
- "…how many publications from my university have a ROR in OpenAlex but not in our CRIS, so that I know where to target a clean-up."
- "…the share of publications with a funder DOI, per institution, so that I can see whether we are an outlier."

*Strategic, about the research portfolio:*
- "…how much grant funding we won for SDG-related projects over the last ten years, so that I can answer the board's sustainability question with evidence instead of anecdote."
- "…which faculties collaborate most with industry, so that I can see where our valorisation story actually sits."

*Leadership and policy:*
- "…an overview of our international co-publication partners by country over time, so that leadership has a factual base for a knowledge security conversation."
- "…how our open access share compares to the other Dutch universities, so that I can brief our library director before the UKB meeting."

All of these are welcome. [`docs/ideas.md`](ideas.md) has twelve ready-made ones across the same three tiers. Taking one from the list is completely fine.

**One note if you are working on knowledge security, research integrity or performance.** Keep it aggregate: institution, country, faculty, year. Not named researchers. These notebooks end up in a public repository, and a risk score attached to a person is a very different object from a count, whatever the underlying data. Ask the facilitator if you are unsure.

Then tell the agent your sentence and add: **"Help me scope this to something buildable in 30 minutes."** It will ask you questions. Answer them. This conversation is the most valuable part of the hour.

**Scope small.** One question, one data source, one or two charts. You can always add more. You cannot un-run out of time.

## Step 3: Install a skill yourself

Everything else is pre-loaded, but do this one by hand so you have seen how it works:

```bash
npx skills add DietrichGebert/ponytail --agent claude-code --copy --yes
```

The `--agent claude-code --copy` part matters: without it, the installer
may symlink the skill instead of copying it, which breaks on Windows
without developer mode, and it may also write to a second directory your
agent doesn't read. This exact command writes a real copy straight into
`.claude/skills/ponytail/` — the one place both OpenCode and Claude Code
look.

`ponytail` is already vendored, so you'll see an "already exists" message.
That's expected and harmless — you're just reinstalling over the copy
that shipped with the repo, as a teaching exercise.

Then open `.claude/skills/ponytail/SKILL.md` and read it.

That is all a skill is: instructions in a text file. This one stops the agent from over-building. You could write one for how your institution checks affiliation metadata, and every agent you run would follow it.

## Step 4: Build

Talk to the agent. Some things that work well:

| Instead of | Say |
|---|---|
| "Write me a query that..." | "Show me the SQL before you run it." |
| "Fix the code" | "This number is wrong: Utrecht cannot have 900 publications. Find out why." |
| "Make it better" | "Run the notebook and show me the error." |
| Nothing, when lost | "Explain what this cell does, in plain language." |

**Watch it update live.** Ask the agent to *"start the marimo preview"* — it handles the details and gives you back a URL (it'll include a `?access_token=...` part; use the whole thing, not just the short version). Open that in your browser and leave the tab up. From then on, every cell in the notebook has a name (`dutch_institutions_query`, `funding_chart`, and so on), so you can say *"change the query in the `funding_chart` cell to sort by year instead"* and the agent edits the file directly — the tab reloads on its own the moment the file changes, no copy-pasting code back and forth. This runs inside your sandbox; if the URL doesn't load in your host browser, see [`docs/troubleshooting.md`](troubleshooting.md).

**See what a reader would see.** The editor view always shows you the code alongside the output — useful while building, but not what you're actually shipping. Ask the agent *"show me app mode"* to switch the preview to the no-code, read-only view — the same thing your exported HTML/WASM dashboard will look like. Good final check before Step 5: if a heading is missing or a chart has no axis labels, this is where you'll notice.

**You are the reviewer.** The agent is fast and confident and will sometimes be confidently wrong: an invented column name, a ROR that resolves to the wrong institution, a count that is off by an order of magnitude. You know what a plausible number looks like for your institution. It does not. That knowledge is why you are in the room.

If your question is strategic, expect a second problem: the data may not directly answer it. There is no "SDG" column, and no "knowledge security risk" field. You will be working with proxies, and the agent will happily present a proxy as if it were the real thing. When that happens, say so in the notebook: *"this uses topic classifications as a stand-in for SDG alignment, which under-counts X."* Naming the proxy is a stronger result than hiding it.

Ask it to check its own work: *"Verify that ROR resolves to the institution you think it does."*

## Step 5: Ship it

At minute 45, stop adding things and make what you have run cleanly.

```bash
./scripts/submit.sh
```

This creates your branch, commits your notebook, pushes it, and opens a pull request with a short checklist. Fill the checklist in honestly, including the parts that do not work. "The WASM export fails" is useful information, not a confession.

If that script fails, open a GitHub issue using the "Workshop idea" template and paste your notebook in there instead. Your idea gets captured either way.

---

# After the session

**Your key expires** on the date in your email. After that:

- Ask whether your institution has its own SURF AI Hub collaboration ([how it works](https://servicedesk.surf.nl/wiki/spaces/WIKI/pages/222464732/Onboarding))
- Or point OpenCode at any other model provider; nothing else in the setup changes

**Everything else keeps working.** The repository, the skills, the sandbox, the notebook template. Same commands, any time.

**Where to go next:**

- [`docs/ideas.md`](ideas.md) for more problems worth solving
- The DuckLake browser view: https://surf-ori.github.io/sprouts/
- Write your own skill: ask your agent, "use the writing-skills skill to help me write a skill for \_\_\_\_"

---

## Quick reference

| | |
|---|---|
| Start | `./scripts/start.sh` |
| Submit | `./scripts/submit.sh` |
| Skills you have | `/skills` inside your agent |
| Install a skill | `npx skills add owner/repo --agent claude-code --copy --yes` |
| Preview a notebook | `uvx marimo edit --sandbox --watch notebooks/<name>/notebook.py` |
| Something broke | [`docs/troubleshooting.md`](troubleshooting.md) |
