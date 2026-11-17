# Power BI Build Specification

Import the CSVs in `Data/processed/dashboard_tables/`. Population prevalence visuals should use the explicitly labelled survey-weighted tables. Keep the caveat: **NHANES August 2021–August 2023 survey estimate; associations are not causal.**

## Page 1 — How big is the problem?

- `dashboard_survey_weighted_kpi.csv`: primary cards for diabetes, prediabetes, and normal population prevalence; show the 95% CI in a subtitle or tooltip.
- `dashboard_kpi.csv`: optional unweighted analytic-sample comparison. Do not mix its percentages into weighted cards.
- `dashboard_status_distribution.csv`: 100% stacked bar or three aligned bars. A bar is easier to compare than a donut.

## Page 2 — Who is most affected?

- `dashboard_survey_weighted_group_prevalence.csv`: primary grouped prevalence bars with confidence intervals, observed `unweighted_n`, `unweighted_cases`, and `reliability_flag` in tooltips.
- `dashboard_dimension_burden.csv`: optional unweighted sample-description table, including lifestyle dimensions not in the weighted minimum set.
- `dashboard_age_bmi_segments.csv`: age × BMI heatmap/matrix with diabetes %, prediabetes %, and n.

## Page 3 — What characteristics are associated?

- `dashboard_survey_weighted_model_associations.csv`: primary forest plot using survey-adjusted odds ratio and CI, reference line at 1, and model n/events/design df in tooltips.
- `dashboard_model_associations.csv`: optional unweighted comparison forest plot.
- Add an explanatory card: “Adjusted association does not mean causation.”

## Page 4 — What should be prioritized?

- `dashboard_priority_segments.csv`: ranked table or horizontal bar of eligible age × BMI segments. Display burden rank, diabetes %, prediabetes %, and n together.
- Use narrative callouts that distinguish age/demographics for **targeting** from BMI and other potentially modifiable factors for **intervention planning**.
- Do not convert rank to a pseudo-precise priority score.

## Relationships and formatting

These are pre-aggregated tables with different grains, so do not create participant-key relationships among them. Use the participant CSV separately only if row-level cross-filtering is required. Weighted prevalence fields are already on a 0–100 scale. Never sum `unweighted_n` across overlapping groups or treat a survey weight as a participant count. Keep model odds ratios on a logarithmic x-axis if supported.
