# Facilitator Guide
## ORI Crash Course: Coding with AI in One Hour

**Audience:** research information professionals, data stewards, library, policy and strategy staff. Assume no Python, no terminal comfort, no Git.
**Group size:** 6 to 12. Above 8, a co-facilitator is not optional.
**Duration:** 60 minutes hands-on, plus mandatory pre-work.
**Setting:** in-person workshop, own laptops.
**Prior knowledge assumed:** what a DOI, ORCID and ROR are; what their own institution's reporting pain looks like. No coding.

---

## Learning objectives

By the end of the session, participants will be able to:

1. **Formulate** a question about their own research information practice, operational or strategic, in a form an AI agent can act on.
2. **Direct** a coding agent through a build: asking for a plan first, inspecting what it proposes, and rejecting output that is wrong.
3. **Evaluate** a result against what they already know about their institution, and say why a number is or is not plausible.
4. **Install and read** an agent skill, and explain what a skill is to a colleague.
5. **Publish** a working artifact to a shared repository.

Objective 3 is the one that matters most and the one most likely to be skipped. Protect it.

**Key vocabulary** (define each once, in passing, never as a list):
agent · skill · sandbox · Marimo notebook · pull request

---

## Read this first: the honest timing problem

You cannot install Docker Sandboxes, authenticate it, install a coding agent, load skills, *and* build something in sixty minutes. Installation alone eats the hour, and it fails differently on every laptop.

So the design splits in two:

| Phase | When | Who does the work |
|---|---|---|
| **Pre-flight** | 5 to 7 days before | Participant, alone, following one page, with a self-test that prints ✅ or ❌ |
| **Session** | The hour itself | Participant builds; you coach |

Anyone who arrives without a green pre-flight goes to the fallback lane. Do not troubleshoot installs during the session. That is the whole point of the split.

### Platform reality check

Docker Sandboxes (`sbx`) supports macOS on Apple Silicon, Linux x86_64 with KVM, and Windows 11 x86_64. Intel Macs and locked-down managed Windows laptops will fail. Expect 10 to 25 percent of a typical SURF/UKB audience to hit this.

**Fallback lane:** GitHub Codespaces launched from the workshop repo. Same repo, same skills, same agent, no local install. Have it ready and tested. Frame it as a lane, not a failure.

### Two agents, one repo

The repo is set up for **OpenCode** with SURF AI Hub, but some participants already run **Claude Code** and will otherwise arrive with none of the skills loaded.

The fix is a directory choice: skills are vendored in **`.claude/skills/`**, which Claude Code reads natively and OpenCode also reads. One copy, both agents, no symlinks. `sbx run claude` and `sbx run opencode` both work.

**Be honest about the difference, out loud, in the framing:**

| | OpenCode lane | Claude Code lane |
|---|---|---|
| Model | SURF AI Hub | Anthropic, participant's own subscription |
| Key | The shared workshop key | Their own |
| Data leaves the Netherlands | No | Yes |
| Everything else | Identical | Identical |

Claude Code cannot use the SURF AI Hub key: the AI Hub speaks the OpenAI API shape and Claude Code expects the Anthropic one. Bridging that needs a proxy, which is not worth doing for an hour.

Say this plainly rather than glossing it. For an audience that cares about digital sovereignty, the contrast is a teaching moment, not an embarrassment. "Same skills, same notebook, different jurisdiction" is the line.

### The model question, now settled

OpenCode is an agentic loop and needs a model that does **tool calling**. All seven models enabled on your AI Hub collaboration have been tested:

- **Use `Sehyo/Qwen3.5-122B-A10B-NVFP4`.** Streams tool calls correctly, full round trip in about three seconds when warm.
- **Fallback: `RedHatAI/gemma-4-31B-it-NVFP4`.** Also works.
- **Do not use `openai/gpt-oss-120b` or `default-text-large`.** They look like the obvious choice, being the always-on ones, and they pass a simple tool test. But OpenCode streams, and when streaming with tools they return an empty response and nothing else. `default-text-large` is just an alias for gpt-oss, so it fails identically.
- The two Qwen2.5 models cannot tool-call at all.

The config in the repo already pins the working models and hides the rest. Re-test only if someone changes which models are enabled for the collaboration.

### Warm the model before the room arrives

This is the one that will bite you on the day. Every tool-capable model is **on-demand**, meaning it unloads when idle. A cold model took between 131 and 264 seconds to answer in testing. The back office shows some as "Running" even when the API reports them unloaded, so do not trust the green dot.

**Send one throwaway request to the workshop model 10 to 15 minutes before the session starts.** `scripts/preflight.sh` does this. Otherwise twelve people hit a cold model at 0:07, everyone waits four minutes, and you have lost the sync point and the room's confidence in the same stroke.

Warm it again if there is a long gap before the build phase.

---

## Pre-flight (send 5 to 7 days ahead)

Send participants the quickstart plus:

- The workshop repo URL
- Their SURF AI Hub API key and its expiry date
- A named cut-off: "reply with your ✅ screenshot by [date], or you go in the Codespaces lane"

Hold one 30-minute optional drop-in two days before. Cap your own effort there.

Track who has replied ✅. Chase at T-3 and T-1. Non-responders default to the fallback lane; tell them rather than asking again.

---

## Materials and room setup

- [ ] Screen mirrored, terminal font readable from the back
- [ ] Your own laptop in the **participant** configuration, not your dev machine
- [ ] Pinned or printed: AI Hub base URL, model name (`Sehyo/Qwen3.5-122B-A10B-NVFP4`), DuckLake catalog URL, repo URL
- [ ] A shared channel or doc where people paste error text (faster than you walking over)
- [ ] One finished notebook open in a tab, ready to show
- [ ] Room setup: tables, people able to see each other, you able to reach every seat in five seconds

---

## Run of show

| Time | Phase | Activity | Format |
|---|---|---|---|
| 0:00 | Hook | Why you, not a developer, are in this room | Whole group |
| 0:07 | Sync | Everyone launches, everyone sees the skill list | Individual, in lockstep |
| 0:12 | Prior knowledge → scoping | One-sentence question, then the agent interrogates it | Individual, you circulate |
| 0:20 | Guided practice | Install one skill by hand, read it | Individual |
| 0:25 | Independent practice | Build | Individual, you float |
| 0:50 | Publish | Branch, commit, pull request | Individual |
| 0:57 | Exit ticket and close | | Whole group |

---

### 0:00 to 0:07 — Hook (7 min)

Say the point out loud, because it is not obvious:

> You are not learning to code. You are learning to *direct* something that codes. Your value in this room is that you know what a bad ROR match looks like, and you know what your board actually asks for in September. The model knows neither. Your job for the next hour is to hold a real question in your head and refuse an answer that is wrong about it.

Cover, fast:

- **What a skill is.** A folder with a Markdown file that tells the agent how to do one thing well. Not code. You can read it. You can write one.
- **Why the sandbox.** The agent runs shell commands. In `sbx` it runs them in a throwaway microVM that sees your project folder and nothing else.
- **Where the model lives.** SURF AI Hub, Dutch infrastructure, your institution's contract. Then the honest caveat about the Claude Code lane above.
- **What you will hand in.** A Marimo notebook, in a pull request, that someone else can open and run.

Show, do not describe, one finished notebook from `surf-ori/dashboards`. Ten seconds. "This is the shape of the thing."

**Then set the scope of "problem" wide, explicitly.** This is a change worth making deliberately, because the room will otherwise default to metadata plumbing:

> This is not only about data quality. Yes, you can ask "how many of our publications are missing a ROR." You can also ask "plot over time how much grant funding we won for SDG-related projects," or "build a knowledge security overview of our past collaborations for the board." Strategic questions are welcome here, and they are usually the harder and more interesting ones.

### 0:07 to 0:12 — Everyone launches together (5 min)

On your count:

```
cd ~/ori-crashcourse
./scripts/start.sh
```

The script asks which agent. Then, inside: `/skills`, or "what skills do you have?"

You are checking that every person sees the skill list. Last sync point. Anyone red here moves to Codespaces now, not in ten minutes.

### 0:12 to 0:20 — Choose the question (8 min)

This decides whether the hour produces anything, so do not let it drift.

Two minutes silent: everyone writes one sentence, **"I want to see \_\_\_ for \_\_\_, so that \_\_\_ ."** The "so that" is what turns a topic into a question.

Then they type it at the agent and add "help me scope this to 30 minutes." The `brainstorming` skill fires and pushes back.

`docs/ideas.md` has twelve seeded questions across three tiers, operational through strategic. Point at it, do not read it aloud.

**Your job here is ruthless scope-cutting.** Half the failed submissions will be over-scoped, not under-skilled. When you see three joins across two sources: "One source, one institution, one chart. Grow it later."

**Strategic questions need a second cut, a different one.** They are usually not too big technically, they are too vague about what would count as an answer. Ask: "What would you put on one slide?" That converts "knowledge security dashboard" into "count of co-authored outputs per partner country per year, flagged against a policy list" in about forty seconds.

**A flag to raise once, quietly, to anyone working on knowledge security, integrity or performance:** keep it aggregate. Institution, country, faculty, year. Not named researchers. These notebooks go into a public repository, and a plausible-looking risk score attached to a person is a different object from a count. Say this as craft, not as a rule, and only to the people it applies to.

### 0:20 to 0:25 — Install one skill by hand (5 min)

Everything else is pre-loaded. This one is theirs:

```
npx skills add DietrichGebert/ponytail --agent claude-code --copy --yes
```

The flags matter and are worth saying out loud once: `--copy` avoids a
symlink (breaks on Windows without developer mode), and `--agent
claude-code` sends it straight to `.claude/skills/`, the one directory
both agents read. `ponytail` is already vendored, so participants will see
an "already exists" message — tell them that's expected, they're just
reinstalling over the copy that shipped with the repo.

Then open `.claude/skills/ponytail/SKILL.md` and read it. Say:

> That is the whole magic. Text in a folder. You just installed a colleague's working habit into your agent. You could write one for how *your* institution decides whether an affiliation counts, and every agent you run would follow it.

Reconnect it to their world: a skill is the executable version of the tacit knowledge that currently lives in one person's head and leaves when they do. That lands with this audience.

If `npx` is slow behind a proxy, move on. The skill is already vendored.

### 0:25 to 0:50 — Build (25 min)

Mostly silent. You float.

**Formative checks, built into the timing:**

At **0:35**, interrupt once, thirty seconds:

> Stop and look at one number your notebook produced. Is it plausible? If it says Utrecht has 900 publications, it is wrong. The agent will not catch that. You will.

Then, individually as you circulate, ask two or three people: *"Where did that number come from?"* If they cannot answer, that is your intervention point, not a chart that looks nice.

At **0:45**:

> Five minutes. Stop adding. Make what you have run cleanly and commit it. Twelve small working notebooks beat three big broken ones.

**Coaching moves, in order of usefulness:**

1. *"Ask it to show you the SQL before it runs it."* Turns a black box into something they can judge.
2. *"Tell it what is wrong, not how to fix it."* They keep trying to write code through the agent. Redirect to describing the symptom.
3. *"Have it run the notebook and paste the error back."* The verification loop is the thing worth learning.
4. *"Ask it to explain that cell in plain language."* For people who have gone quiet because they lost the thread.

**Differentiation.**

*Struggling, or non-technical and stalling:*
- Give them a question from `docs/ideas.md` outright. Choosing is itself a task; remove it.
- Have them start from an existing notebook in `surf-ori/dashboards` and change one thing. Modifying beats creating.
- Pair two people at one screen. One types, one judges. The judging role is the real skill and needs no setup.
- Lower the bar out loud: "one chart, one sentence, ship it."

*Ahead of the room, or already technical:*
- Point at `wasm-compatibility` and have them make it render as a real page.
- Cross two sources instead of one, or add an interactive control.
- Best extension: use `writing-skills` to write a new skill capturing their institution's own rule, and submit it alongside the notebook. A genuine contribution, and it will keep them busy.
- Ask them to help a neighbour. Say it as a promotion, not a chore.

**Failure modes:**

| Symptom | Response |
|---|---|
| Agent invents column names | "Ask it to run `DESCRIBE` on the table first." The `ori-ducklake` skill covers this; it did not read it. |
| Query hangs on `openalex.works` | Expected, ~365M rows. Filter first, aggregate second. Never `UNNEST` authorships on the full table. |
| Agent silent or very slow on first message | Cold on-demand model spinning up. Up to four minutes. Say so out loud so the room does not think it is broken, and warm it next time. |
| Strategic question has no data behind it | Common and important. Help them find the nearest available proxy and *name it as a proxy* in the notebook. That is the honest answer, and better than a fabricated one. |
| Runs locally, breaks in WASM export | `wasm-compatibility` skill. If time is short, ship anyway and note it in the PR. |
| Agent loops on the same broken fix | "Stop, start over, and this time write the plan first." |
| Someone silently stuck and embarrassed | Sit down next to them. Most common real failure, and it looks like nothing. |

### 0:50 to 0:57 — Publish (7 min)

```
./scripts/submit.sh
```

Branch, commit, push, pull request with the self-assessment checklist.

If `gh` auth fails, have them open the GitHub issue template on their phone and paste the notebook in. The idea gets captured either way, which is what you actually need.

### 0:57 to 1:00 — Exit ticket and close (3 min)

**Exit ticket.** Not "did you enjoy it." Everyone writes, in the PR description or on a card, one sentence:

> "The number I trusted least was \_\_\_ , because \_\_\_ ."

That tests objective 3 directly, takes ninety seconds, and gives you a real read on whether the room learned to look at output critically or just learned to prompt.

Then:

- Two or three people say their question in one sentence. Not demos, no screen sharing, no time.
- **Key expiry.** Say the date out loud. Say what happens after: their institution's own AI Hub collaboration, or ask you.
- **What persists.** The repo, the skills, the sandbox. This is the "it works after the meeting" promise. Make it explicit.
- Where the PRs go and when you will review them.

---

## Common misconceptions to address

| Misconception | Correct understanding | How to address it |
|---|---|---|
| "I need to learn Python first" | You need to judge output, not produce it. The judging is the skill in short supply. | Say it in the hook. Repeat it to the first person who apologises for not being technical. |
| "The agent knows about ORI" | It knows general patterns. Everything specific comes from the skills and the data. | Ask someone to request a column that does not exist and watch it invent one. Thirty seconds, unforgettable. |
| "If it runs, it is right" | Running and correct are unrelated properties. | The 0:35 interrupt exists for this. |
| "A skill is a program" | It is Markdown. Readable in a minute, writable in ten. | The hand-install step at 0:20. Make them open the file. |
| "Strategic questions are too fuzzy for this" | They are the highest-value ones. They need sharper definition, not more data. | The "what goes on one slide" question. |
| "The sandbox means the output is safe" | The sandbox protects *your laptop*. It says nothing about whether the analysis is sound or appropriate to publish. | Raise with anyone doing risk, integrity or performance work. |

---

## After the session

- Triage PRs within a week while it is warm. Merge generously; a rough notebook that renders is a win.
- Anything unfinished becomes a GitHub issue with the author tagged, not a dead branch.
- **Note which questions clustered, and which tier they came from.** If the room reached for strategic questions and the data could not support them, that is a finding about the ORI monitor roadmap, and probably the most valuable output of the hour.
- Note where the pre-loaded skills failed to help. Those gaps are the next skills to write.
- Revoke or let expire the shared key on schedule.

---

## Quality checks before you run this

- [ ] Every activity traces to a learning objective
- [ ] Timing adds to 60 and has been walked through once against a clock
- [ ] Nothing runs longer than 25 minutes without a change of format
- [ ] Both agent lanes tested end to end
- [ ] Model warmed 10 to 15 minutes before start
- [ ] Streaming tool calling re-verified if the enabled model list changed
- [ ] Codespaces fallback launched successfully at least once, with `SURF_AIHUB_API_KEY` set as a Codespaces secret at github.com/settings/codespaces *before* creating the codespace (it's only injected at container creation) — `./scripts/preflight.sh` now runs there too (no `sbx` required) and will catch a missing/bad key before the workshop, same as the sbx lane
- [ ] `docs/ideas.md` spans operational, strategic and leadership questions, not just data quality
- [ ] You have a plan for the person who arrives with nothing installed

---

## What "success" means

Not: everyone shipped a polished dashboard.

Yes: every participant can state a question they care about, has seen an agent make progress on it, has read a skill file and understood it, has doubted at least one number out loud, and has one artifact with their name on it. Eight of twelve reaching that is a good hour.

---

*Lesson structure (objectives, differentiation, formative assessment, misconceptions, quality checks) follows the `teaching-lesson-plan` skill from [mohitagw15856/pm-claude-skills](https://github.com/mohitagw15856/pm-claude-skills).*
