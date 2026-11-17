# Methodology

## Data and cohort

The project uses the NHANES August 2021–August 2023 `_L` release. Twelve component files are joined to `DEMO_L` with left joins on `SEQN`. Every raw component is checked for a non-missing, unique key before joining. The analytic cohort is adults age 20+ with observed glycohemoglobin (`LBXGH`), producing 5,767 unique participants.

HbA1c status is defined as Normal `<5.7%`, Prediabetes `5.7% to <6.5%`, and Diabetes `>=6.5%`. This is an analytic classification, not a clinical diagnosis. Self-reported diabetes is retained separately.

## Cleaning and missing data

NHANES refusal/don't-know codes are converted to missing where applicable. In particular, `PAD800=9999` and `ALQ121=77/99` are not treated as quantities. Alcohol frequency is collapsed from documented categories; `PAD800` is described as duration per moderate leisure-time activity session and is not mislabelled as weekly activity volume.

Descriptive tables use available observations within each displayed dimension. The primary regression uses complete cases across all included predictors: 4,783 participants (587 diabetes events), excluding 984 analytic participants with one or more missing model fields. This is explicit and may introduce selection bias.

## Statistical model

The primary analysis is an unweighted binary logistic regression:

```text
HbA1c-defined Diabetes (1) vs Normal or Prediabetes (0)
  ~ age (per 10 years)
  + sex
  + race/ethnicity
  + education
  + income-to-poverty ratio
  + BMI (per 5 kg/m²)
  + systolic blood pressure (per 10 mmHg)
  + smoking history
  + sleep-duration group
```

Reference groups are Female, Non-Hispanic White, College Graduate, Never Smoked, and 6–8 hours sleep. Results are odds ratios with profile-likelihood 95% confidence intervals and p-values. These estimates describe adjusted associations in the complete-case analytic sample.

HbA1c is excluded because it defines the outcome. Fasting glucose is excluded because it is a closely related glycemic marker and is available only in a fasting subsample. Waist is excluded from the primary model because it overlaps strongly with BMI. Age group is not combined with continuous age. Physical-activity session duration and alcohol frequency remain descriptive only because their interpretation/eligibility patterns do not support clean primary-model exposure measures.

## Complex survey design

The data are one NHANES release: August 2021–August 2023. No cycles are combined, so no multi-cycle weight is needed. The outcome is derived from the blood analyte `LBXGH`; the cycle-specific [GHB_L analytic notes](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/GHB_L.htm) direct analysts to the phlebotomy weight. Survey analyses therefore use:

- weight: `WTPH2YR`
- masked stratum: `SDMVSTRA`
- masked PSU: `SDMVPSU`
- `survey::svydesign(..., nest=TRUE)`

The weight adjusts unequal selection probabilities and phlebotomy nonresponse. Strata and PSU identifiers are needed for design-correct variance estimates. The analytic cohort contains 15 strata, both PSU codes in every stratum, and 15 design degrees of freedom. All 5,767 analytic records have positive `WTPH2YR`.

The primary survey regression is the same complete-case conceptual model as the unweighted regression and uses `svyglm(..., family=quasibinomial())`. Coefficient-level t tests and 95% confidence intervals use the 15 design degrees of freedom. Domain-specific descriptive estimates use logit confidence intervals. If a displayed subgroup has fewer than 30 observations or relative standard error above 30%, it is flagged for caution.

`survey.lonely.psu="adjust"` and `survey.adjust.domain.lonely=TRUE` provide a conservative adjustment when a subgroup domain leaves only one contributing PSU in a stratum. The full adult analytic design itself has both PSUs represented in every stratum.

Unweighted results remain available and describe the observed analytic sample. Survey-weighted results are intended to describe the U.S. civilian noninstitutionalized adult population covered by this release, subject to the outcome, complete-case, and other limitations below. `WTMEC2YR` remains retained for general MEC work, while `WTSAF2YR` would be required for analyses using fasting glucose.

## Other limitations

- Cross-sectional observational data cannot establish causality or intervention effects.
- Weighted regression remains complete-case and may differ systematically from the full analytic cohort; survey weighting does not repair predictor item nonresponse automatically.
- A single first oscillometric BP reading is used; a mean of valid readings could be preferable in a future clinical refinement.
- HbA1c-only classification can differ from diagnosis, medication history, or alternate laboratory criteria.
- Race/ethnicity findings should guide equity monitoring and targeting, not biological or causal claims.
