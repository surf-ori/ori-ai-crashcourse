# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "marimo",
#     "duckdb>=1.5.2",
#     "altair",
#     "pandas",
#     "pyarrow",
# ]
# ///

import marimo

__generated_with = "0.24.0"
app = marimo.App(width="full", app_title="SDG Funding Timeline")


@app.cell
async def wasm_dependencies():
    # WASM export (uvx marimo export html-wasm) runs inside Pyodide in the
    # browser. duckdb and its extensions aren't bundled by default there,
    # so install them at runtime via micropip. On a normal desktop run
    # this cell is a no-op -- the PEP 723 header above already handles it.
    import sys

    if "pyodide" in sys.modules:
        import micropip

        _ = await micropip.install(["duckdb"])
    return


@app.cell
def imports():
    import altair as alt
    import duckdb
    import marimo as mo

    return alt, duckdb, mo


@app.cell
def _(mo):
    mo.md("""
    # SDG Funding Timeline for Dutch Universities

    Track SDG-related research funding over time. Select one or more Dutch universities to compare.

    **What this shows:**
    - **SDG Publications**: Count of publications tagged with UN Sustainable Development Goals
    - **SDG Projects**: Funding amounts for projects with SDG-related subjects

    **Limitations:**
    - Award amounts in OpenAlex are not directly available; we show publication counts
    - Project subjects are keyword-based, not explicit SDG mappings
    """)
    return


@app.cell
def _(con, mo):
    # Load Dutch institutions for selection
    dutch_institutions = con.execute("""
        SELECT 
            ROR_LINK as ror,
            full_name_in_English as name,
            acronym_EN as acronym,
            main_grouping
        FROM lake."nl-orgs".baseline
        ORDER BY name
    """).df()

    # Create multi-select dropdown
    institution_selector = mo.ui.multiselect(
        options={row['name']: row['ror'] for _, row in dutch_institutions.iterrows()},
        label="Select universities to compare",
        # default=["https://ror.org/008xxew50"]  # Vrije Universiteit Amsterdam
    )
    institution_selector
    return (institution_selector,)


@app.cell
def _(con, institution_selector, mo):
    # SDG-tagged publications by year for selected institutions
    selected_rors = institution_selector.value

    if not selected_rors:
        mo.md("Select at least one institution to view data.")
        sdg_publications = None
    else:
        # Build ROR list for filtering
        ror_list = ", ".join([f"'{ror}'" for ror in selected_rors])
    
        sdg_publications = con.execute(f"""
            WITH institution_works AS (
                SELECT 
                    w.id,
                    w.publication_year,
                    inst.ror,
                    inst.display_name as institution_name
                FROM lake.openalex.works w,
                     UNNEST(w.authorships) AS authorship,
                     UNNEST(authorship.institutions) AS inst
                WHERE inst.ror IN ({ror_list})
                  AND w.publication_year >= 2016
                  AND w.sustainable_development_goals IS NOT NULL
            ),
            sdg_counts AS (
                SELECT 
                    iw.publication_year,
                    sdg.display_name as sdg_name,
                    iw.institution_name
                FROM institution_works iw,
                     UNNEST(iw.sustainable_development_goals) AS sdg
            )
            SELECT 
                publication_year,
                sdg_name,
                institution_name,
                COUNT(*) as count
            FROM sdg_counts
            GROUP BY publication_year, sdg_name, institution_name
            ORDER BY publication_year, sdg_name, institution_name
        """).df()
    
        mo.md(f"**SDG Publications by Year** ({len(selected_rors)} institution(s) selected)")
        mo.ui.table(sdg_publications)
    return (sdg_publications,)


@app.cell
def _(alt, sdg_publications):
    if sdg_publications is not None and not sdg_publications.empty:
        chart = (
            alt.Chart(sdg_publications)
            .mark_line()
            .encode(
                x=alt.X("publication_year:Q", title="Year"),
                y=alt.Y("count:Q", title="Publication Count"),
                color=alt.Color("sdg_name:N", title="SDG"),
            )
            .properties(
                title="SDG-Tagged Publications Over Time",
                height=300
            )
        )
        chart
    return


@app.cell
def _(con, institution_selector, mo):
    # Project funding by year for all Dutch institutions with SDG-related subjects
    selected_rors = institution_selector.value

    if not selected_rors:
        sdg_projects = None
    else:
        sdg_projects = con.execute(f"""
            WITH dutch_rors AS (
                SELECT UNNEST(STR_SPLIT_REGEX(STRING_AGG(ROR_LINK, ', '), ', ')) as ror
                FROM lake."nl-orgs".baseline
            ),
            sdg_projects AS (
                SELECT 
                    p.id,
                    p.title,
                    p.startDate,
                    p.granted.fundedAmount as amount,
                    p.granted.currency,
                    o.legalName as organization
                FROM lake.openaire.projects p,
                     UNNEST(p.organizations) AS org,
                     UNNEST(org.pids) AS pid
                WHERE p.granted IS NOT NULL
                  AND p.granted.fundedAmount IS NOT NULL
                  AND p.startDate >= '2016-01-01'
                  AND pid.scheme = 'ROR'
                  AND pid.value IN (SELECT UNNEST(ror) FROM dutch_rors)
                  AND EXISTS (
                      SELECT 1 FROM UNNEST(p.subjects) AS subject
                      WHERE LOWER(subject) LIKE '%sustainable%'
                         OR LOWER(subject) LIKE '%environment%'
                         OR LOWER(subject) LIKE '%climate%'
                         OR LOWER(subject) LIKE '%energy%'
                         OR LOWER(subject) LIKE '%water%'
                         OR LOWER(subject) LIKE '%poverty%'
                         OR LOWER(subject) LIKE '%health%'
                         OR LOWER(subject) LIKE '%education%'
                         OR LOWER(subject) LIKE '%equality%'
                         OR LOWER(subject) LIKE '%biodiversity%'
                         OR LOWER(subject) LIKE '%ecosystem%'
                         OR LOWER(subject) LIKE '%renewable%'
                         OR LOWER(subject) LIKE '%green%'
                         OR LOWER(subject) LIKE '%circular%'
                  )
            )
            SELECT 
                EXTRACT(YEAR FROM startDate) as year,
                SUM(amount) as total_amount,
                currency
            FROM sdg_projects
            GROUP BY year, currency
            ORDER BY year
        """).df()
    
        mo.md(f"**SDG-Related Project Funding** (Dutch institutions, 2016+)")
        mo.ui.table(sdg_projects)
    return (sdg_projects,)


@app.cell
def _(alt, sdg_projects):
    if sdg_projects is not None and not sdg_projects.empty:
        chart = (
            alt.Chart(sdg_projects)
            .mark_bar()
            .encode(
                x=alt.X("year:O", title="Year"),
                y=alt.Y("amount:Q", title="Funding Amount (EUR)"),
            )
            .properties(
                title="SDG-Related Project Funding Over Time",
                height=300
            )
        )
        chart
    return


@app.cell
def _(duckdb):
    # Connection setup - no changes from template
    con = duckdb.connect()
    con.execute("INSTALL ducklake; LOAD ducklake;")
    con.execute("INSTALL httpfs; LOAD httpfs;")
    con.execute("""
        ATTACH 'ducklake:https://objectstore.surf.nl/cea01a7216d64348b7e51e5f3fc1901d:sprouts/catalog.ducklake'
        AS lake (READ_ONLY, CREATE_IF_NOT_EXISTS false)
    """)
    return (con,)


@app.cell
def _(mo):
    mo.md("""
    ## Notes on this dashboard

    **Data sources:**
    - SDG publications: OpenAlex `works` table with `sustainable_development_goals` array
    - Project funding: OpenAIRE `projects` table with keyword-based SDG matching

    **Known limitations:**
    1. **No award amounts in OpenAlex**: The `awards` array in works doesn't include funding amounts, only award IDs
    2. **Keyword-based project matching**: Projects are matched by subject keywords, not explicit SDG labels
    3. **Performance**: UNNEST operations on large tables can be slow; filtered to 2016+ to reduce scope

    **Suggestions for improvement:**
    - Add more institutions by selecting from the dropdown
    - Adjust the year range to focus on specific periods
    - Extend the keyword list for more comprehensive project matching
    """)
    return


if __name__ == "__main__":
    app.run()
