# Tableau Portfolio Dashboard

This folder prepares the existing validated NHANES outputs for a three-dashboard Tableau portfolio story. It does not recalculate the statistical analysis and is not part of the production R pipeline.

## Files

- `data/tableau_diabetes_burden.csv`: three HbA1c statuses, weighted prevalence and CI, unweighted comparison, and observed counts.
- `data/tableau_subgroup_prevalence.csv`: 50 subgroup/outcome estimates across six stakeholder dimensions.
- `data/tableau_adjusted_associations.csv`: 17 survey-adjusted model comparisons with odds ratios, CIs, role categories, and CI-crossing flags.
- `TABLEAU_BUILD_SPEC.md`: exact Tableau Desktop construction instructions.
- `prepare_tableau_extracts.R`: optional reproducible extract-preparation script using only existing final outputs.

To refresh the Tableau extracts after the validated pipeline has been run:

```bash
Rscript tableau/prepare_tableau_extracts.R
```

The primary dashboard values are survey-weighted estimates for the U.S. civilian noninstitutionalized adult population represented by NHANES August 2021–August 2023. All `observed_*`, `unweighted_n`, and `unweighted_cases` fields are actual analytic-sample counts, not weighted population counts. The analysis is cross-sectional and observational; it supports association language, not causal claims.
