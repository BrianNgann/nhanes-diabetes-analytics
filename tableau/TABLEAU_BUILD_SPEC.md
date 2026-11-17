# Tableau Build Specification — NHANES Diabetes Burden

## Recommended implementation

Build a Tableau packaged workbook (`.twbx`) manually from the three CSVs in `tableau/data/`. A generated `.twb` was deliberately not created: Tableau workbook XML is version-sensitive, and a fragile generated workbook is less reliable than three clean extracts plus explicit construction steps.

Use Tableau Desktop or Tableau Public on macOS. Choose a **fixed desktop size of 1,200 × 800 px** for all dashboards. Use a white background, generous spacing, and one restrained palette:

- Diabetes / primary mark: `#B44C43` muted red
- Prediabetes: `#D79A3B` amber
- Normal / neutral: `#4C7A78` teal
- CI and secondary text: `#6B7280` gray
- Caution: `#A16207` dark amber
- Body text: `#25313C`

Use Tableau Book or Arial. Titles 22–26 pt, section headings 14–16 pt, body/tooltips 10–11 pt. Avoid legends when direct labels are clearer.

## Connect the data

1. Open Tableau and select **Text file**.
2. Connect to `tableau/data/tableau_diabetes_burden.csv`; name the source `Burden`.
3. Add separate data sources for `tableau_subgroup_prevalence.csv` (`Subgroups`) and `tableau_adjusted_associations.csv` (`Associations`).
4. Do not join or relate the sources. They have different grains and are designed for separate worksheets.
5. Confirm prevalence/CI/OR fields are Numbers (decimal), order fields are Numbers (whole), and caution/crossing fields are Boolean.

## Calculated fields

Create these only where indicated; source fields already contain the statistical calculations.

### Burden — `Status Color`

```text
IF [category] = "Diabetes" THEN "Diabetes"
ELSEIF [category] = "Prediabetes" THEN "Prediabetes"
ELSE "Normal"
END
```

### Subgroups — `Caution Label`

```text
IF [use_caution] THEN "Use caution: small or imprecise estimate" ELSE "" END
```

### Associations — `CI Line Length`

```text
[ci_upper] - [ci_lower]
```

No Tableau calculation should recompute weighted prevalence, confidence intervals, or odds ratios.

# Dashboard 1 — Diabetes Burden

Title: **An estimated one in three adults has prediabetes or diabetes**

This follows from 24.25% prediabetes plus 10.45% diabetes. Subtitle: “Survey-weighted estimates among U.S. civilian noninstitutionalized adults, NHANES August 2021–August 2023.”

## Worksheet `Burden | Status prevalence`

- Source: `Burden`
- Columns: `weighted_prevalence_percent`
- Rows: `category`, sorted ascending by `status_order`
- Marks: Bar
- Color: `Status Color`
- Label: `weighted_prevalence_percent`, one decimal, suffix `%`
- Axis: fixed 0–70%; title “Survey-weighted prevalence (%)”
- Tooltip:

```text
<category>
Population estimate: <display_estimate>
Observed cases: <observed_cases> of <observed_sample_n>
Weight: <weight_variable>
```

Add CI error bars using Analytics → Error Bars → Custom, lower value `weighted_ci_lower_percent` and upper value `weighted_ci_upper_percent`. If the installed Tableau version does not permit custom endpoints on the bar, use a dual-axis Gantt construction: circle at estimate plus Gantt line from lower to upper.

## Worksheet `Burden | Observed sample n`

- Text mark only: `MAX(observed_sample_n)`
- Label: “5,767 observed participants”
- Caption: “Observed analytic-sample size—not a weighted population count.”

## Worksheet `Burden | Weighting comparison`

- Columns: Measure Values (`weighted_prevalence_percent`, `unweighted_sample_percent`)
- Rows: `category`
- Mark: Circle or thin bar
- Measure Names on color: weighted = dark teal; unweighted = light gray
- Keep this compact beneath the main chart.
- Annotation: “Weighting lowers the estimated diabetes prevalence from 12.5% in the observed sample to 10.5%.”

## Layout

- Top 15%: title, subtitle, methodology badge “Survey-weighted | WTPH2YR”.
- Middle 60%: status prevalence chart.
- Bottom left: observed sample context.
- Bottom right: small weighted/unweighted comparison.
- Footer: “HbA1c classification: Normal <5.7%; Prediabetes 5.7–<6.5%; Diabetes ≥6.5%. Observational analysis.”

# Dashboard 2 — Who Is Most Affected?

Default title: **Diabetes burden rises substantially with age**

Use a title parameter so the title changes with the selected dimension if desired: “Survey-weighted diabetes burden by <Parameters.Dimension Selector>”. The default age title is supported by estimates of 2.87%, 11.99%, and 17.42% across increasing age groups.

## Parameter `Dimension Selector`

String list:

```text
Age group
BMI category
Sex
Race/ethnicity
Education
Income group
```

## Worksheet `Groups | Weighted prevalence`

- Source: `Subgroups`
- Filter: `dimension = Dimension Selector` using a calculated Boolean `[dimension] = [Dimension Selector]`; keep True.
- Filter: `category`; default Diabetes, allow Prediabetes.
- Rows: `group`, sorted by `group_order` for age/BMI/income/education. For race/ethnicity, optionally sort descending by estimate after explaining that this changes the source order.
- Columns: `estimate`
- Marks: Circle
- Add 95% CI with a Gantt bar or custom error bar from `ci_lower` to `ci_upper`.
- Color: `use_caution`; regular marks muted red, caution marks dark amber.
- Label: `estimate`, one decimal with `%`.
- Axis: start at zero; use one shared scale within a selected dimension.
- Tooltip:

```text
<dimension>: <group>
Outcome: <category>
Survey-weighted prevalence: <display_estimate>
Observed cases: <unweighted_cases>
Observed subgroup n: <unweighted_n>
Reliability: <reliability_flag>

Observed n is not a weighted population count.
```

Do not hide the Underweight BMI row. Its two estimates are flagged “Use caution”; display the warning icon/color and broad interval.

## Worksheet `Groups | Sample context`

- Rows: `group`
- Columns: `unweighted_n`
- Mark: thin gray bar
- Label: `unweighted_n`
- Apply the same dimension and outcome filters.
- Title: “Observed subgroup sample sizes”

## Layout and interactions

- Left 20%: dimension selector and Diabetes/Prediabetes filter.
- Center 60%: prevalence dot-and-whisker chart.
- Right 20%: observed-n bars and interpretation note.
- Use a highlight action from the prevalence chart to the sample-size chart.
- Keep a fixed note: “Intervals reflect the complex survey design. Wider intervals mean less precise estimates.”

# Dashboard 3 — Adjusted Associations

Title: **Age and BMI remain strongly associated with diabetes after adjustment**

Subtitle: “Survey-weighted logistic regression; diabetes versus normal or prediabetes; n=4,783.”

## Worksheet `Model | Forest plot`

- Source: `Associations`
- Rows: `comparison`, nested beneath `factor_role`; sort roles by `role_order` and comparisons by `comparison_order`.
- Columns: `odds_ratio`
- Marks: Circle
- Add horizontal CI whiskers from `ci_lower` to `ci_upper` using a Gantt-bar dual axis:
  1. Put `ci_lower` on Columns and change mark to Gantt Bar.
  2. Put `CI Line Length` on Size.
  3. Add `odds_ratio` as a second axis with Circle marks.
  4. Synchronize axes and hide the secondary header.
- Add reference line at 1 labelled “No association”.
- Use logarithmic axis if comfortable for stakeholders; otherwise use a linear axis starting near 0 and explain the reference line.
- Color circles by `factor_role` using four muted shades. Use opacity or shape to distinguish `association_signal`; avoid interpreting “CI includes 1” as proof of no relationship.
- Label circles with `odds_ratio` to two decimals only when space permits.
- Tooltip:

```text
<comparison>
<display_or>
p-value: <p_value>
Interpretation: <interpretation>
Role: <factor_role>
Observed model n: <model_n>; diabetes events: <outcome_events>
Survey weight: <weight_variable>; inference df: <inference_df>

Association does not establish causation.
```

## Worksheet `Model | Interpretation key`

Create a small text table with the four `factor_role` values and these explanations:

- Targeting: demographic — useful for identifying populations with higher observed burden.
- Targeting: socioeconomic — useful for equity-oriented outreach and access planning.
- Modifiable clinical — potentially useful for intervention planning; not evidence of an intervention effect.
- Modifiable lifestyle — observed adjusted associations may be imprecise or absent in this model.

## Layout

- Top: title, model subtitle, “Survey-weighted” badge.
- Left 72%: forest plot.
- Right 28%: interpretation key and limitations.
- Footer: “HbA1c and glucose were excluded as predictors; BMI and waist were not entered together. Cross-sectional observational analysis.”

# Final assembly and publishing on macOS

1. Create the three dashboards above at 1,200 × 800 fixed size.
2. Apply consistent fonts, padding, colors, number formats, and footer notes.
3. Dashboard → Actions: add only the described highlight/filter interactions.
4. Test the dimension parameter and outcome filter on Dashboard 2.
5. Verify every tooltip distinguishes population estimates from observed counts.
6. File → Save As and save `NHANES_Diabetes_Tableau.twbx` inside `tableau/`.
7. If publishing to Tableau Public, use Server → Tableau Public → Save to Tableau Public. Confirm that CSV extracts are embedded in the packaged workbook.
8. Capture one PNG screenshot of each dashboard for a future portfolio README update.

## Required visual QA

- Dashboard 1 must display 65.3% Normal, 24.3% Prediabetes, and 10.5% Diabetes after one-decimal formatting.
- Dashboard 2 default Diabetes view must show age estimates 2.9%, 12.0%, and 17.4%.
- Dashboard 3 must show Age OR 1.70 (1.62–1.80) and BMI OR 1.61 (1.51–1.72).
- Underweight BMI estimates must retain the caution warning.
- No observed `n` may be called a population count.
- No title, tooltip, annotation, or legend may use “causes,” “leads to,” “impact,” or “effect” to describe these associations.
