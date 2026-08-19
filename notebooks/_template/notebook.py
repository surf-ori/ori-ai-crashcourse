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

__generated_with = "0.20.4"
app = marimo.App(width="full", app_title="{{TITLE}}")


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
    # {{TITLE}}

    Your work starts here. The query below already produces a chart --
    run this notebook and you should see one within a few seconds,
    no edits needed.
    """)
    return


@app.cell
def _(duckdb):
    # Connects read-only to the SURF ORI DuckLake catalog. No credentials
    # needed -- this bucket is public for reads.
    con = duckdb.connect()
    con.execute("INSTALL ducklake; LOAD ducklake;")
    con.execute("INSTALL httpfs; LOAD httpfs;")
    con.execute("""
        ATTACH 'ducklake:https://objectstore.surf.nl/cea01a7216d64348b7e51e5f3fc1901d:sprouts/catalog.ducklake'
        AS lake (READ_ONLY, CREATE_IF_NOT_EXISTS false)
    """)
    return (con,)


@app.cell
def _(con, mo):
    # Small and fast: a count of Dutch institutions in OpenAlex, by type.
    # Filtered and aggregated on a 120K-row table -- never scan
    # openalex.works unfiltered, it's 364M rows and will hang.
    dutch_institutions = con.execute("""
        SELECT type, COUNT(*) AS institution_count
        FROM lake.openalex.institutions
        WHERE country_code = 'NL'
        GROUP BY type
        ORDER BY institution_count DESC
    """).df()
    mo.ui.table(dutch_institutions)
    return (dutch_institutions,)


@app.cell
def _(alt, dutch_institutions, mo):
    chart = (
        alt.Chart(dutch_institutions)
        .mark_bar()
        .encode(
            x=alt.X("institution_count:Q", title="Institutions"),
            y=alt.Y("type:N", sort="-x", title=None),
        )
        .properties(title="Dutch institutions in OpenAlex, by type")
    )
    mo.ui.altair_chart(chart)
    return


@app.cell
def _(mo):
    mo.md("""
    ## Try it yourself

    Change the query above, or ask your agent something like:
    *"Show me the same chart but for Germany instead of the Netherlands."*
    """)
    return


# --- Stated proxy example (commented out) ----------------------------------
# Strategic questions rarely have a direct column to query. This shows the
# pattern for using a proxy honestly: name it, and say what it misses.
# Uncomment and adapt if your question needs one.
#
# @app.cell
# def _(con, mo):
#     # PROXY: topic classification stands in for "SDG-related research".
#     # There is no ground-truth SDG field in OpenAlex. This undercounts
#     # projects whose SDG relevance isn't visible in the abstract, and
#     # may overcount generic environmental topics that aren't really
#     # SDG-aligned. Say this in your own notebook wherever you use a
#     # proxy -- naming it is a stronger result than hiding it.
#     sdg_proxy = con.execute("""
#         SELECT sdg.display_name, COUNT(*) AS work_count
#         FROM lake.openalex.works w,
#              UNNEST(w.sustainable_development_goals) AS sdg
#         WHERE w.publication_year >= 2020
#         GROUP BY sdg.display_name
#         ORDER BY work_count DESC
#         LIMIT 10
#     """).df()
#     mo.ui.table(sdg_proxy)
#     return (sdg_proxy,)


if __name__ == "__main__":
    app.run()
