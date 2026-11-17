# Complex-survey estimates for NHANES August 2021-August 2023.
# Unweighted outputs from 01_descriptive_and_logistic_model.R remain unchanged.
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(survey); library(DBI); library(RSQLite)})
if (!exists("analysis_data", inherits = FALSE)) source(file.path("R", "v2", "01_prepare_analysis_data.R"))

options(survey.lonely.psu = "adjust", survey.adjust.domain.lonely = TRUE)
analysis_dir <- file.path("Data", "processed", "analysis")
dashboard_dir <- file.path("Data", "processed", "dashboard_tables")

survey_data <- analysis_data %>% mutate(
  age_per_10_years = age / 10,
  bmi_per_5_units = bmi / 5,
  systolic_bp_per_10 = systolic_bp / 10,
  sex = relevel(factor(sex), "Female"),
  race_ethnicity = relevel(factor(race_ethnicity), "Non-Hispanic White"),
  education = relevel(factor(education), "College Graduate"),
  smoking_status = relevel(factor(smoking_status), "Never Smoked"),
  sleep_group = relevel(factor(sleep_group), "6 to 8 hours"),
  complete_primary_model = complete.cases(age_per_10_years, sex, race_ethnicity,
    education, income_ratio, bmi_per_5_units, systolic_bp_per_10,
    smoking_status, sleep_group, diabetes_binary)
)

nhanes_design <- svydesign(
  ids = ~survey_psu, strata = ~survey_stratum, weights = ~phlebotomy_weight,
  data = survey_data, nest = TRUE
)
if (degf(nhanes_design) <= 0) stop("Survey design has no residual design degrees of freedom.")

estimate_prop <- function(design, expression, label, n, cases) {
  result <- svyciprop(as.formula(paste0("~I(", expression, ")")), design,
                      method = "logit", level = 0.95, na.rm = TRUE)
  ci <- confint(result)
  data.frame(category = label, estimate = 100 * coef(result)[1],
             ci_lower = 100 * ci[1], ci_upper = 100 * ci[2],
             standard_error = 100 * SE(result)[1], unweighted_n = n,
             unweighted_cases = cases)
}

weighted_overall <- bind_rows(
  estimate_prop(nhanes_design, "diabetes_status == 'Normal'", "Normal", nrow(survey_data), sum(survey_data$diabetes_status == "Normal")),
  estimate_prop(nhanes_design, "diabetes_status == 'Prediabetes'", "Prediabetes", nrow(survey_data), sum(survey_data$diabetes_status == "Prediabetes")),
  estimate_prop(nhanes_design, "diabetes_status == 'Diabetes'", "Diabetes", nrow(survey_data), sum(survey_data$diabetes_status == "Diabetes"))
) %>% mutate(dimension = "Diabetes status", estimate_type = "Survey-weighted",
             weight_variable = "WTPH2YR", .before = 1) %>%
  mutate(across(c(estimate, ci_lower, ci_upper, standard_error), ~round(.x, 2)))

group_variables <- c(age_group = "Age group", sex = "Sex", bmi_category = "BMI category",
                     race_ethnicity = "Race/ethnicity", education = "Education",
                     income_group = "Income group")
weighted_groups <- bind_rows(lapply(names(group_variables), function(variable) {
  values <- unique(na.omit(as.character(survey_data[[variable]])))
  bind_rows(lapply(values, function(value) {
    keep <- !is.na(survey_data[[variable]]) & as.character(survey_data[[variable]]) == value
    group_design <- subset(nhanes_design, keep)
    n_group <- sum(keep)
    bind_rows(
      estimate_prop(group_design, "diabetes_status == 'Diabetes'", "Diabetes", n_group, sum(keep & survey_data$diabetes_status == "Diabetes")),
      estimate_prop(group_design, "diabetes_status == 'Prediabetes'", "Prediabetes", n_group, sum(keep & survey_data$diabetes_status == "Prediabetes"))
    ) %>% mutate(dimension = unname(group_variables[variable]), group = value, .before = 1)
  }))
})) %>% mutate(estimate_type = "Survey-weighted", weight_variable = "WTPH2YR",
               reliability_flag = if_else(unweighted_n < 30 | standard_error / estimate > 0.30,
                                          "Use caution", "Meets basic display rule")) %>%
  mutate(across(c(estimate, ci_lower, ci_upper, standard_error), ~round(.x, 2)))

survey_model_design <- subset(nhanes_design, complete_primary_model)
survey_model <- svyglm(
  diabetes_binary ~ age_per_10_years + sex + race_ethnicity + education + income_ratio +
    bmi_per_5_units + systolic_bp_per_10 + smoking_status + sleep_group,
  design = survey_model_design, family = quasibinomial()
)
if (!isTRUE(survey_model$converged)) stop("Survey-weighted logistic regression did not converge.")

term_labels <- c(
  age_per_10_years="Age (per 10 years)", sexMale="Male vs Female",
  `race_ethnicityMexican American`="Mexican American vs Non-Hispanic White",
  `race_ethnicityNon-Hispanic Asian`="Non-Hispanic Asian vs Non-Hispanic White",
  `race_ethnicityNon-Hispanic Black`="Non-Hispanic Black vs Non-Hispanic White",
  `race_ethnicityOther Hispanic`="Other Hispanic vs Non-Hispanic White",
  `race_ethnicityOther Race`="Other Race vs Non-Hispanic White",
  `education9th-11th Grade`="9th-11th Grade vs College Graduate",
  `educationHigh School/GED`="High School/GED vs College Graduate",
  `educationLess than 9th Grade`="Less than 9th Grade vs College Graduate",
  `educationSome College/AA`="Some College/AA vs College Graduate",
  income_ratio="Income-to-poverty ratio (per 1 unit)", bmi_per_5_units="BMI (per 5 kg/m2)",
  systolic_bp_per_10="Systolic BP (per 10 mmHg)",
  `smoking_statusEver Smoked`="Ever smoked vs Never smoked",
  `sleep_groupLess than 6 hours`="Sleep <6 vs 6-8 hours",
  `sleep_groupMore than 8 hours`="Sleep >8 vs 6-8 hours")
beta <- coef(survey_model)
beta_se <- sqrt(diag(vcov(survey_model)))
inference_df <- degf(survey_model_design)
critical_t <- qt(0.975, df = inference_df)
ci <- cbind(beta - critical_t * beta_se, beta + critical_t * beta_se)
p_values <- 2 * pt(abs(beta / beta_se), df = inference_df, lower.tail = FALSE)
terms <- setdiff(names(beta), "(Intercept)")
weighted_model_results <- data.frame(
  predictor = case_when(
    terms == "age_per_10_years" ~ "Age", terms == "income_ratio" ~ "Income",
    terms == "bmi_per_5_units" ~ "BMI", terms == "systolic_bp_per_10" ~ "Systolic blood pressure",
    grepl("^race_ethnicity", terms) ~ "Race/ethnicity", grepl("^education", terms) ~ "Education",
    grepl("^sleep_group", terms) ~ "Sleep duration", grepl("^sex", terms) ~ "Sex",
    grepl("^smoking_status", terms) ~ "Smoking history", TRUE ~ terms),
  comparison = unname(term_labels[terms]),
  odds_ratio = round(exp(coef(survey_model)[terms]), 3),
  ci_lower = round(exp(ci[terms, 1]), 3), ci_upper = round(exp(ci[terms, 2]), 3),
  p_value = signif(p_values[terms], 3), factor_role = case_when(
    grepl("^(age|sex|race)", terms) ~ "Targeting: demographic",
    grepl("^(education|income)", terms) ~ "Targeting: socioeconomic",
    grepl("^(bmi|systolic)", terms) ~ "Intervention planning: modifiable clinical",
    TRUE ~ "Intervention planning: modifiable lifestyle"),
  model_n = sum(survey_data$complete_primary_model), outcome_events = sum(survey_data$diabetes_binary[survey_data$complete_primary_model]),
  inference_df = inference_df,
  estimate_type = "Survey-weighted", weight_variable = "WTPH2YR",
  interpretation = ifelse(exp(ci[terms, 1]) > 1, "Higher survey-adjusted odds",
                   ifelse(exp(ci[terms, 2]) < 1, "Lower survey-adjusted odds",
                          "No clear survey-adjusted association at the 95% CI level"))
)

unweighted_status <- survey_data %>% count(diabetes_status, name = "unweighted_n") %>%
  mutate(unweighted_percent = 100 * unweighted_n / sum(unweighted_n))
prevalence_comparison <- weighted_overall %>%
  select(diabetes_status = category, survey_weighted_percent = estimate,
         survey_ci_lower = ci_lower, survey_ci_upper = ci_upper) %>%
  left_join(unweighted_status, by = "diabetes_status") %>%
  mutate(unweighted_percent = round(unweighted_percent, 2),
         percentage_point_difference = round(survey_weighted_percent - unweighted_percent, 2))

unweighted_model <- read.csv(file.path(analysis_dir, "logistic_regression_results.csv"))
regression_comparison <- weighted_model_results %>%
  select(comparison, survey_weighted_or = odds_ratio, survey_weighted_ci_lower = ci_lower,
         survey_weighted_ci_upper = ci_upper) %>%
  left_join(select(unweighted_model, comparison, unweighted_or = odds_ratio,
                   unweighted_ci_lower = ci_lower, unweighted_ci_upper = ci_upper), by = "comparison") %>%
  mutate(or_difference = round(survey_weighted_or - unweighted_or, 3),
         same_direction = (survey_weighted_or >= 1) == (unweighted_or >= 1))

design_summary <- data.frame(
  cycle = "NHANES August 2021-August 2023", weight = "WTPH2YR",
  strata = "SDMVSTRA", psu = "SDMVPSU", nest = TRUE,
  lonely_psu_handling = "survey.lonely.psu='adjust'; survey.adjust.domain.lonely=TRUE",
  analytic_n = nrow(survey_data), positive_weight_n = sum(survey_data$phlebotomy_weight > 0),
  strata_count = length(unique(survey_data$survey_stratum)), design_degrees_freedom = degf(nhanes_design),
  regression_inference = "Coefficient t tests and 95% CIs use 15 design degrees of freedom",
  cycles_combined = 1, multi_cycle_weight_needed = FALSE)

write.csv(weighted_overall, file.path(analysis_dir, "survey_weighted_overall_prevalence.csv"), row.names = FALSE)
write.csv(weighted_groups, file.path(analysis_dir, "survey_weighted_group_prevalence.csv"), row.names = FALSE)
write.csv(weighted_model_results, file.path(analysis_dir, "survey_weighted_logistic_regression_results.csv"), row.names = FALSE)
write.csv(prevalence_comparison, file.path(analysis_dir, "weighted_unweighted_prevalence_comparison.csv"), row.names = FALSE)
write.csv(regression_comparison, file.path(analysis_dir, "weighted_unweighted_regression_comparison.csv"), row.names = FALSE)
write.csv(design_summary, file.path(analysis_dir, "survey_design_summary.csv"), row.names = FALSE)
saveRDS(survey_model, file.path(analysis_dir, "survey_weighted_logistic_model.rds"))
write.csv(weighted_overall, file.path(dashboard_dir, "dashboard_survey_weighted_kpi.csv"), row.names = FALSE)
write.csv(weighted_groups, file.path(dashboard_dir, "dashboard_survey_weighted_group_prevalence.csv"), row.names = FALSE)
write.csv(weighted_model_results, file.path(dashboard_dir, "dashboard_survey_weighted_model_associations.csv"), row.names = FALSE)

con <- dbConnect(SQLite(), file.path("Data", "database", "nhanes_diabetes.sqlite"))
dbWriteTable(con, "dashboard_survey_weighted_kpi", weighted_overall, overwrite = TRUE)
dbWriteTable(con, "dashboard_survey_weighted_group_prevalence", weighted_groups, overwrite = TRUE)
dbWriteTable(con, "dashboard_survey_weighted_model_associations", weighted_model_results, overwrite = TRUE)
dbDisconnect(con)
message("Survey-weighted analysis completed with WTPH2YR; design df=", degf(nhanes_design), ".")
