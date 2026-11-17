# NHANES Diabetes Pipeline Audit

Audit completed before refactoring. Raw XPT files were preserved and are read only.

## Source mapping and join logic

| Component | Variables used | Purpose |
|---|---|---|
| `DEMO_L` | `SEQN`, `RIAGENDR`, `RIDAGEYR`, `RIDRETH3`, `DMDEDUC2`, `INDFMPIR`, `WTMEC2YR`, `SDMVSTRA`, `SDMVPSU` | key, demographics, socioeconomic measures, survey design |
| `BMX_L` | `BMXBMI`, `BMXWAIST` | BMI and waist |
| `BPXO_L` | `BPXOSY1`, `BPXODI1` | first oscillometric BP reading |
| `DIQ_L` | `DIQ010` | self-reported diabetes |
| `GHB_L` | `LBXGH` | HbA1c and analytic classification |
| `GLU_L` | `LBXGLU`, `WTSAF2YR` | fasting glucose and its subsample weight |
| `TCHOL_L` / `HDL_L` | `LBXTC`, `LBDHDD` | lipids |
| `SMQ_L` | `SMQ020` | ever smoked 100 cigarettes |
| `PAQ_L` | `PAD800` | minutes per moderate leisure-time activity session |
| `SLQ_L` | `SLD012` | weekday/workday sleep hours |
| `ALQ_L` | `ALQ121` | past-year alcohol frequency category |

`DEMO_L` is the left-hand population frame. Each component is left-joined once on `SEQN`. All 12 raw components have zero missing keys and zero duplicate keys, and the final table has 5,767 rows with 5,767 distinct `SEQN` values; therefore, joins do not multiply participants.

## Cohort and derivations

The active cohort correctly implements age 20+ and non-missing `LBXGH`. Status is Normal `<5.7`, Prediabetes `5.7 to <6.5`, and Diabetes `>=6.5`. Age and BMI categories are mutually exclusive and exhaustive when their source measure is present. Income, sleep, alcohol-frequency, and moderate-session-duration groups are now explicitly derived and documented.

## Findings from the original implementation

- The original output had unique `SEQN`, no participants under 20, and complete diabetes classification.
- Quality checks ran **after** database publication, allowing invalid data to be published before failure. The active pipeline validates first.
- `PAD800=9999` was retained as if it were 9,999 minutes; it is now missing. The variable was also labelled too broadly as physical-activity minutes; its actual meaning is duration per moderate leisure-time activity session.
- `ALQ121=77/99` (refused/don't know) was retained numerically and the ordered frequency codes were not interpretable as a continuous quantity. They are now cleaned and grouped descriptively.
- Survey weights, strata, and PSU variables existed but were dropped. They are now retained and prominently flagged as not yet applied.
- Fasting glucose has substantial design-related missingness and a specific subsample weight. It is retained for context but excluded from the primary model.
- The original reporting tables were logically valid unweighted summaries, but the race × education table could foreground small cells and did not cover all requested story dimensions.
- The original pipeline used the first BP measurement only. This remains for comparability and is documented as a limitation.

## Active controls

The active workflow asserts unique component keys, deterministic participant order, valid adult cohort, exact outcome/HbA1c agreement, cleaned special codes, populated outputs, CSV/database row agreement, and successful model convergence. SQL priority segments require at least 100 participants and use a transparent prevalence rank, not an invented score.
