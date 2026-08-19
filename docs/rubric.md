# Rubric
## ORI Crash Course submissions

**What this is for.** Giving useful feedback on pull requests, and telling you which ideas are worth pulling into the ORI dashboard roadmap. It is a coaching instrument, not a grade.

**What this is not for.** Ranking people. Say so out loud at the start of the session, or half the room will optimise for looking competent instead of trying something hard.

**Explicitly not assessed:** Python fluency, code elegance, prior technical experience, how much the agent did versus the participant. If the agent wrote all of it and the participant caught two errors and shipped a working thing, that is a full pass. That is the skill being taught.

---

## Minimum viable submission

Everything below this bar still counts as a completed workshop. Meet all four and you have succeeded:

- [ ] A branch and pull request exist under your name
- [ ] `notebooks/<slug>/notebook.py` opens in Marimo without a fatal error
- [ ] `metadata.json` has a title and your name
- [ ] The PR description says, in one sentence, what ORI problem this addresses

An honest half-finished notebook with a clear problem statement beats a polished notebook that answers nothing anyone asked.

---

## The five criteria

Each is scored 1 to 4. Twenty points total, but the profile matters more than the sum. A 4 on framing with a 2 on the artifact is a *better* workshop outcome than the reverse, because the framing is the part that cannot be automated.

---

### 1. Problem framing
*Is there a real research information question here, cut to a size that fits an hour?*

Questions at any altitude count equally: operational ("which records are missing a ROR"), strategic ("how has our SDG-related funding moved over ten years"), or leadership-facing ("what does our international collaboration profile look like for a knowledge security discussion"). Do not score a strategic question lower because it is harder to ground. Score the framing on its own merits and let criterion 2 handle the grounding.

| | |
|---|---|
| **1 — Absent** | No stated question, or a generic demo with no ORI content. |
| **2 — Vague** | A topic rather than a question ("something about ORCID"). Would not tell you whether the answer was useful. |
| **3 — Clear** | A specific, answerable question, appropriately scoped. Names the entity, the source and the measure. |
| **4 — Grounded** | As above, and connected to a real decision or workflow: who would act on this, and what would they do differently. Traces to something in the ORI use case landscape (reporting, assessment, analysis) or names a concrete gap the author has actually met at work. |

**Look for the "so that".** "How many of our publications have a funder DOI" is a 3. "…because our NWO reporting currently takes three people two weeks" is a 4. Likewise, "an SDG funding dashboard" is a 2; "SDG-related grant income per year, because the board asks every autumn and we currently answer from memory" is a 4.

---

### 2. Data grounding
*Does it touch real ORI data, and is it honest about what the data can and cannot say?*

| | |
|---|---|
| **1 — Ungrounded** | Invented, hardcoded or hallucinated data. Column names that do not exist. |
| **2 — Connected** | Real data queried successfully, but the numbers were not sanity-checked. |
| **3 — Checked** | Real data, and at least one result was verified against something the author already knew (institution size, a known count, a spot-checked record). |
| **4 — Caveated** | As above, and the notebook states its limits: coverage gaps, what a null actually means here, why a proxy is a proxy. Identifiers verified to resolve to the right thing. |

**Look for:** did they check that the ROR resolves to the institution they think it does? That single habit separates 3 from 2 and is the most transferable thing in the whole workshop.

**For strategic questions, the proxy is the whole game.** There is no SDG field and no knowledge-security field. Anyone answering those questions is standing on a substitute: topic classifications, funder programme names, partner country. A submission that names its proxy and says what it misses is a 4 even if the number is rough. A submission that presents a proxy as the real measure is a 2, however polished the chart. This is the most important single judgement in the rubric, because it is exactly the failure mode that survives into a board slide.

**Ethics note for risk, integrity and performance questions.** Aggregate units only: institution, country, faculty, year. A submission that scores or ranks named individuals does not get a grounding score; send it back with a note. Say this before the session as well as after, so it never comes up as a surprise.

---

### 3. Working artifact
*Does it run, and can someone else open it?*

| | |
|---|---|
| **1 — Broken** | Does not open, or errors on first cell. |
| **2 — Runs locally** | Opens in `marimo edit`, produces output, WASM export untested or failing. |
| **3 — Renders** | Exports to HTML/WASM and displays correctly. Dependencies pinned in the script header. |
| **4 — Usable** | As above, and someone unfamiliar can understand it without a guide: titles, axis labels, a sentence saying what they are looking at, at least one working interactive control. |

**Note:** WASM failure is a common, forgivable outcome under time pressure. A 2 with the failure documented in the PR is better than a 2 with silence. Do not penalise honesty here.

---

### 4. Agent craft
*Was the agent directed, or just prompted and accepted?*

| | |
|---|---|
| **1 — Passive** | Accepted the first output without inspection. No evidence of review. |
| **2 — Iterative** | Went back and forth, fixed things as they broke. Reactive but engaged. |
| **3 — Directed** | Used at least one skill deliberately. Asked to see plans or SQL before execution. Caught and corrected a substantive error. |
| **4 — Systematic** | Spec or plan before code. Verification asked for and checked. Wrote a reusable instruction, or noted where an existing skill fell short and why. |

**Evidence:** the PR description, commit messages, and whether the notebook contains checks the agent would not have added unprompted. You are looking for the participant's judgement showing up in the artifact.

---

### 5. Shareability
*Could this become part of `surf-ori/dashboards`?*

| | |
|---|---|
| **1 — Orphaned** | No metadata, unclear authorship, does not follow the repository layout. |
| **2 — Present** | Correct location and `metadata.json`. |
| **3 — Documented** | As above, plus a data-source note and any known limitations. ORCID and GitHub handle in metadata. |
| **4 — Adoptable** | Could be merged with light review. Follows repository conventions, dependencies pinned, screenshot in `public/`, open questions stated so someone else could pick it up. |

---

## Reading the profile

| Pattern | What it means | What to say |
|---|---|---|
| High framing, low artifact | Ran out of time on a good problem. **The most valuable failure in the room.** | Turn it into a repo issue and offer to pair on it. |
| High artifact, low framing | Technically fluent, chasing the tool. | "This works. What decision would it change?" |
| High agent craft, low everything | Learned the meta-skill, no domain traction yet | Fine. Give them a sharper problem next time. |
| Low grounding, high artifact | **Watch this one.** A convincing dashboard built on numbers nobody checked, or a proxy presented as a measure. | The single most important correction to make, kindly and specifically. Most likely to occur on strategic questions, and most likely to end up in front of a decision-maker. |

---

## Facilitator scoring sheet

| Participant | Framing | Grounding | Artifact | Agent craft | Shareable | Total | Follow up? |
|---|---|---|---|---|---|---|---|
| | | | | | | /20 | |

**After scoring, ask yourself two questions about the cohort, not the individuals:**

1. Which problems came up more than once, and at which altitude? Unsolicited requirements-gathering for the ORI monitor, and probably worth more than any single notebook.
2. Which strategic questions could the open data not support at all? That is a gap list with direct roadmap value: it tells you what the monitor would have to add to answer the questions people actually have.
3. Where did the pre-loaded skills fail to help? Those gaps are the next skills to write.
