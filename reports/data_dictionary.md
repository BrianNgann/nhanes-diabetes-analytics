# Data and Dashboard Dictionary

## Participant-level source of truth

`Data/processed/nhanes_diabetes_analysis.csv` has one row per adult age 20+ with observed HbA1c. Blank cells are missing values.

| Column(s) | Source / definition |
|---|---|
| `SEQN` | NHANES respondent identifier; unique |
| `age`, `sex`, `race_ethnicity`, `education` | `RIDAGEYR`, `RIAGENDR`, `RIDRETH3`, `DMDEDUC2` |
| `income_ratio`, `income_group` | `INDFMPIR`; ratio and dashboard bands |
| `age_group` | 20–39, 40–59, 60+ |
| `bmi`, `bmi_category` | `BMXBMI` kg/m²; standard underweight/normal/overweight/obese bands |
| `waist` | `BMXWAIST`, cm |
| `systolic_bp`, `diastolic_bp` | `BPXOSY1`, `BPXODI1`, mmHg; first oscillometric reading |
| `hba1c` | `LBXGH`, percent; defines status |
| `glucose` | `LBXGLU`, fasting mg/dL; subsample measure |
| `cholesterol`, `hdl` | `LBXTC`, `LBDHDD`, mg/dL |
| `sleep_hours`, `sleep_group` | `SLD012`; <6, 6–8, >8 hours |
| `smoking_status` | `SMQ020`; ever vs never smoked 100 cigarettes |
| `physical_activity_minutes` | cleaned `PAD800`; minutes per moderate leisure-time activity session, not weekly volume |
| `activity_duration_group` | <30, 30–59, or 60+ minutes among observed `PAD800` responses |
| `alcohol_frequency_code` | cleaned `ALQ121` code 0–10; lower nonzero codes generally mean more frequent use |
| `alcohol_frequency_group` | none past year, <monthly, weekly-to-monthly, or 2+ times/week |
| `diabetes_self_report` | `DIQ010`: Yes, No, Borderline, or missing |
| `diabetes_status` | HbA1c Normal, Prediabetes, Diabetes |
| `diabetes_binary` | 1 for HbA1c Diabetes; 0 otherwise |
| `phlebotomy_weight` | `WTPH2YR`; primary survey weight because HbA1c is a blood analyte |
| `mec_exam_weight` | `WTMEC2YR`; retained but not used for the HbA1c analysis |
| `fasting_subsample_weight` | `WTSAF2YR`; available only for fasting-subsample participants |
| `survey_stratum`, `survey_psu` | `SDMVSTRA`, `SDMVPSU`; retained but not currently applied |

## Power BI tables

| File / SQLite object | Grain | Intended use |
|---|---|---|
| `dashboard_kpi` | one row for the analytic cohort | KPI cards |
| `dashboard_status_distribution` | one row per HbA1c status | burden distribution |
| `dashboard_dimension_burden` | one row per category within a named dimension | demographic, socioeconomic, BMI, and lifestyle bars |
| `dashboard_age_bmi_segments` | one row per age × BMI cell with n≥30 | heatmap / segmentation matrix |
| `dashboard_priority_segments` | one row per age × BMI cell with n≥100 | transparent ranked action table |
| `dashboard_model_associations` | one row per model coefficient/comparison | odds-ratio forest plot |
| `dashboard_survey_weighted_kpi` | one row per HbA1c status | primary population prevalence, 95% CI, observed denominator and cases |
| `dashboard_survey_weighted_group_prevalence` | one row per group × outcome | primary population subgroup prevalence with CI and reliability flag |
| `dashboard_survey_weighted_model_associations` | one row per model coefficient/comparison | primary survey-adjusted odds-ratio forest plot |

`Data/processed/analysis/model_summary.csv` is one row describing model population, events, missing-data loss, fit statistic, and inference scope. `hba1c_self_report_context.csv` is one row per HbA1c-status × self-report combination. Quality files report one row per variable or validation check.

Survey analysis files include `survey_design_summary.csv`, `survey_weighted_overall_prevalence.csv`, `survey_weighted_group_prevalence.csv`, `survey_weighted_logistic_regression_results.csv`, and weighted-versus-unweighted comparison tables. In prevalence outputs, `estimate`, `ci_lower`, and `ci_upper` are percentages; `unweighted_n` is the observed denominator and `unweighted_cases` is the observed numerator. Neither is a weighted population count.
