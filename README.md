# NHANES Diabetes Burden and Risk-Factor Analytics

**At a glance:** An R and SQL pipeline for the public-use 2021–2023 NHANES cycle. The survey-weighted estimate of diabetes prevalence is **10.45%** (95% CI 9.21–11.84) among the represented U.S. adult population. See the [executive summary](reports/executive_summary.md) for context and limitations.

This portfolio project helps public-health decision makers understand the diabetes burden in an adult NHANES analytic sample, identify groups with higher observed burden, and distinguish characteristics useful for population targeting from potentially modifiable characteristics useful for intervention planning.

The project preserves two clearly labelled result sets: **unweighted** outputs describe the observed analytic sample, while **survey-weighted** outputs use the NHANES design to support inference to the U.S. civilian noninstitutionalized adult population represented by the August 2021–August 2023 cycle. Findings remain observational associations, not causal effects.

## End-to-end architecture

```text
Raw NHANES 2021–2023 XPT files (read only)
  → R preparation and feature engineering
  → validated participant-level source of truth
  → SQLite + SQL descriptive reporting views
  → R unweighted and complex-survey analyses
  → dashboard-ready CSVs
  → Power BI (to be built by the user)
```

- **R** reads XPT files, validates joins, performs unweighted analysis, and uses the `survey` package for weighted prevalence and survey-adjusted regression.
- **SQLite / SQL** provides a lightweight relational reporting layer for repeatable aggregations and demonstrates a database-backed workflow. It is not presented as a scalability requirement for this dataset.
- **Power BI** is the planned interactive communication and decision-support layer. This repository prepares its inputs and specification; it intentionally does not include a generated `.pbix`.

## Reproduce everything

From the project root, with R packages `haven`, `dplyr`, `tidyr`, `DBI`, `RSQLite`, `broom`, and `survey` installed:

```bash
Rscript R/00_run_pipeline.R
```

The runner fails on an invalid cohort, duplicate `SEQN`, invalid survey fields, nonpositive phlebotomy weights, model failure, incomplete confidence intervals, database/CSV disagreement, or missing outputs. Legacy scripts are under `R/v1/`; the active implementation is under `R/v2/` and `R/analysis/`.

The public-use source XPT files are included under `Data/` so this command can run without a separate download. The participant-level CSV, SQLite database, and fitted model files are generated locally and excluded from the repository. The small aggregate tables are included so results can be reviewed without running R.

## Main outputs

- `Data/processed/nhanes_diabetes_analysis.csv`: trusted participant-level table (one row per eligible adult)
- `Data/database/nhanes_diabetes.sqlite`: participant table, SQL views, and model-result tables
- `Data/processed/dashboard_tables/`: Power BI-ready descriptive and model CSVs
- `Data/processed/analysis/`: model results, model metadata, classification context, and fitted model object
- `Data/processed/quality/`: missingness and validation evidence

The first two outputs and fitted model objects are generated when the pipeline runs; they are not stored in this portfolio copy.

See [methodology](reports/methodology.md), [data dictionary](reports/data_dictionary.md), [executive summary](reports/executive_summary.md), [pipeline audit](NHANES_PROJECT_AUDIT.md), and [Power BI specification](powerbi/dashboard_spec.md).

The selected survey design is `ids=SDMVPSU`, `strata=SDMVSTRA`, and `weights=WTPH2YR`, with `nest=TRUE`. `WTPH2YR` is required because HbA1c is a blood analyte in this release; see the official [GHB_L analytic notes](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/GHB_L.htm) and [NHANES weighting tutorial](https://wwwn.cdc.gov/nchs/nhanes/tutorials/weighting.aspx). Only one two-year release is analyzed, so no multi-cycle weight is constructed.
