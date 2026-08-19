# Ideas

Twelve starting questions, four per tier, from operational to strategic to
leadership-facing. Taking one of these outright is completely fine — choosing
is itself a task, and removing it can help if you're stuck.

**A note before you start.** If your question touches knowledge security,
research integrity or performance, keep the unit of analysis aggregate:
institution, country, faculty, year. Not named researchers. These notebooks
go into a public repository, and a plausible-looking number attached to a
person is a different object from a count, whatever the underlying data.
This is craft, not a rule — the reason is that a wrong aggregate is a bug,
but a wrong number next to someone's name is a different kind of problem
entirely.

---

## Tier 1 — Operational (the data itself)

**1. ROR coverage gaps between sources**
I want to see which publications have a ROR-resolved institution in OpenAlex
but not in our CRIS, so that I know where to target a metadata clean-up.
*Touches: `openalex.works` (`authorships[].institutions[].ror`),
`cris.publications` (`repository_info.ror`). Scope: one institution, join on
DOI, count and list the mismatches. 30 minutes.*

**2. Funder DOI coverage per institution**
I want to see the share of publications with a funder recorded, per
institution, so that I can see whether we're an outlier compared to peers.
*Touches: `openalex.works` (`funders[].id`, `funders[].ror`). Scope: filter
to a handful of Dutch institutions by `country_code = 'NL'`, group by
institution, compute the share with a non-empty `funders` array. 30 minutes.*

**3. ISSN harmonisation gaps**
I want to see which journals have a different ISSN recorded in OpenAlex
sources versus OpenAPC, so that I know where our APC records might be
under-matched.
*Touches: `openalex.sources` (`issn_l`), `openapc.apc` (`issn`, `issn_l`,
`issn_print`, `issn_electronic`). Scope: one publisher or a sample of 50
journals, compare `issn_l` values. 30 minutes.*

**4. OA status disagreement between OpenAlex and the CRIS**
I want to see how often OpenAlex says a publication is open access but our
CRIS access-rights field disagrees, so that I know whether our repository
metadata is trustworthy for OA reporting.
*Touches: `openalex.works` (`open_access.is_oa`), `cris.publications`
(`ar:Access`). Scope: one institution, join on DOI, count disagreements.
30 minutes.*

---

## Tier 2 — Strategic (the research portfolio)

**5. SDG-related grant funding over time**
"Plot over time how much funding my institution won for SDG-related
projects and publications."
*Touches: `openaire.projects` (`granted.totalCost`, `fundings[]`),
`openalex.works` (`sustainable_development_goals[]`). Proxy: topic
classification stands in for SDG alignment; it will miss projects whose SDG
relevance isn't visible in the abstract, and over-count generic
environmental topics. Say so in the notebook. Scope: one institution, one
SDG or all 17 grouped, publication years 2018–present. 30 minutes.*

**6. Industry co-authorship by faculty**
I want to see which faculties collaborate most with industry, so that I can
see where our valorisation story actually sits.
*Touches: `openalex.works` (`authorships[].institutions[].type = 'company'`,
`authorships[].institutions[].ror`). Proxy: OpenAlex has no "faculty"
field — this needs a name-based or affiliation-string proxy for faculty,
and will misattribute anyone with a joint or unclear affiliation. Say so.
Scope: one institution, last 5 years, count of works with at least one
company co-author. 30 minutes.*

**7. APC spend against open access share**
I want to see our APC spend per year against our overall open access share,
so that I can tell whether paying for gold OA is actually moving the needle.
*Touches: `openapc.apc` (`euro`, `period`, `institution`), `openalex.works`
(`open_access.is_oa`, `open_access.oa_status`). Scope: one institution, last
5 years, two aligned charts. 30 minutes.*

**8. Diamond OA journal uptake by discipline**
I want to see how much of our output lands in diamond OA journals, broken
down by discipline, so that I can see whether a diamond OA push would suit
some faculties more than others.
*Touches: `openaire.publications` (`isInDiamondJournal`), `openalex.works`
(`primary_topic.field`). Proxy: diamond-OA flagging comes from OpenAIRE and
discipline from OpenAlex's topic model — joining them on DOI will drop
anything not present in both, and topic assignment is itself a model
output, not a ground truth. Say so. Scope: one institution, last 5 years.
30 minutes.*

---

## Tier 3 — Leadership and policy

**9. International co-publication partners by country, over time**
"Build a knowledge security overview of past research collaborations for
university leadership."
*Touches: `openalex.works` (`authorships[].institutions[].country_code`),
`authorships[].institutions[].ror`. Scope to: co-authored outputs per
partner country per year. Aggregate only — never a named researcher. 30
minutes.*

**10. Open access share benchmarked against other Dutch universities**
I want to see our open access share compared to the other Dutch
universities, so that I can brief our library director before the UKB
meeting.
*Touches: `openalex.works` (`open_access.is_oa`), `openalex.institutions`
(`country_code = 'NL'`, `display_name`). Scope: all Dutch universities
(`type = 'education'`), last 3 years, one bar chart. 30 minutes.*

**11. Research portfolio concentration by topic against strategic priorities**
I want to see how concentrated our research output is by topic, so that
leadership can see whether our stated strategic priorities match where our
publications actually are.
*Touches: `openalex.works` (`primary_topic.field`, `primary_topic.domain`),
joined to one institution via `authorships[].institutions[].ror`. Proxy:
"strategic priority" has no data field — you'll need to hand-code a short
list of priority topics/fields to compare against. Say so. Scope: one
institution, last 5 years, top 10 fields by share. 30 minutes.*

**12. Grant success profile by funder programme**
I want to see our project counts and total funding broken down by funder
programme, so that leadership can see which programmes are worth investing
facilitation effort in.
*Touches: `openaire.projects` (`fundings[].fundingStream.id`,
`fundings[].shortName`, `granted.totalCost`, `h2020Programmes[]`). Scope:
one institution (via `organizations[].legalName` on linked publications, or
a known project code prefix), last 5 years. 30 minutes.*
