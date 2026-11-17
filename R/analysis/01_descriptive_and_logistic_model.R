# Stakeholder-focused descriptive estimates and adjusted diabetes association model.
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(broom); library(DBI); library(RSQLite)})
if (!exists("analysis_data", inherits = FALSE)) source(file.path("R", "v2", "01_prepare_analysis_data.R"))

analysis_dir <- file.path("Data", "processed", "analysis")
dashboard_dir <- file.path("Data", "processed", "dashboard_tables")
dir.create(analysis_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(dashboard_dir, recursive = TRUE, showWarnings = FALSE)

# The primary model uses upstream/targeting characteristics. HbA1c defines the outcome;
# glucose is a downstream glycemic marker and fasting-subsample measure, so neither is a predictor.
model_data <- analysis_data %>%
  transmute(
    diabetes = diabetes_binary,
    age_per_10_years = age / 10,
    sex = relevel(factor(sex), "Female"),
    race_ethnicity = relevel(factor(race_ethnicity), "Non-Hispanic White"),
    education = relevel(factor(education), "College Graduate"),
    income_ratio,
    bmi_per_5_units = bmi / 5,
    systolic_bp_per_10 = systolic_bp / 10,
    smoking_status = relevel(factor(smoking_status), "Never Smoked"),
    sleep_group = relevel(factor(sleep_group), "6 to 8 hours")
  ) %>% drop_na()

primary_model <- glm(
  diabetes ~ age_per_10_years + sex + race_ethnicity + education + income_ratio +
    bmi_per_5_units + systolic_bp_per_10 + smoking_status + sleep_group,
  data = model_data, family = binomial()
)
if (!isTRUE(primary_model$converged)) stop("Primary logistic regression did not converge.")

term_labels <- c(
  age_per_10_years = "Age (per 10 years)", sexMale = "Male vs Female",
  `race_ethnicityMexican American` = "Mexican American vs Non-Hispanic White",
  `race_ethnicityNon-Hispanic Asian` = "Non-Hispanic Asian vs Non-Hispanic White",
  `race_ethnicityNon-Hispanic Black` = "Non-Hispanic Black vs Non-Hispanic White",
  `race_ethnicityOther Hispanic` = "Other Hispanic vs Non-Hispanic White",
  `race_ethnicityOther Race` = "Other Race vs Non-Hispanic White",
  `education9th-11th Grade` = "9th-11th Grade vs College Graduate",
  `educationHigh School/GED` = "High School/GED vs College Graduate",
  `educationLess than 9th Grade` = "Less than 9th Grade vs College Graduate",
  `educationSome College/AA` = "Some College/AA vs College Graduate",
  income_ratio = "Income-to-poverty ratio (per 1 unit)",
  bmi_per_5_units = "BMI (per 5 kg/m2)",
  systolic_bp_per_10 = "Systolic BP (per 10 mmHg)",
  `smoking_statusEver Smoked` = "Ever smoked vs Never smoked",
  `sleep_groupLess than 6 hours` = "Sleep <6 vs 6-8 hours",
  `sleep_groupMore than 8 hours` = "Sleep >8 vs 6-8 hours"
)
term_types <- c(
  age_per_10_years="Targeting: demographic", sexMale="Targeting: demographic",
  income_ratio="Targeting: socioeconomic", bmi_per_5_units="Intervention planning: modifiable clinical",
  systolic_bp_per_10="Intervention planning: modifiable clinical",
  `smoking_statusEver Smoked`="Intervention planning: modifiable lifestyle",
  `sleep_groupLess than 6 hours`="Intervention planning: modifiable lifestyle",
  `sleep_groupMore than 8 hours`="Intervention planning: modifiable lifestyle"
)

model_results <- tidy(primary_model, conf.int = TRUE, exponentiate = TRUE) %>%
  filter(term != "(Intercept)") %>%
  transmute(
    predictor = if_else(term == "age_per_10_years", "Age",
                if_else(term == "income_ratio", "Income",
                if_else(term == "bmi_per_5_units", "BMI",
                if_else(term == "systolic_bp_per_10", "Systolic blood pressure",
                if_else(grepl("^race_ethnicity", term), "Race/ethnicity",
                if_else(grepl("^education", term), "Education",
                if_else(grepl("^sleep_group", term), "Sleep duration",
                if_else(grepl("^sex", term), "Sex",
                if_else(grepl("^smoking_status", term), "Smoking history", term))))))))),
    comparison = unname(term_labels[term]), odds_ratio = round(estimate, 3),
    ci_lower = round(conf.low, 3), ci_upper = round(conf.high, 3),
    p_value = signif(p.value, 3),
    factor_role = case_when(
      grepl("^race_ethnicity", term) ~ "Targeting: demographic",
      grepl("^education", term) ~ "Targeting: socioeconomic",
      TRUE ~ unname(term_types[term])),
    model_n = nobs(primary_model), outcome_events = sum(model_data$diabetes),
    interpretation = case_when(
      ci_lower > 1 ~ "Higher adjusted odds",
      ci_upper < 1 ~ "Lower adjusted odds",
      TRUE ~ "No clear adjusted association at the 95% CI level")
  )
if (anyNA(model_results$comparison) || anyNA(model_results$factor_role)) stop("Unmapped model term.")

model_summary <- data.frame(
  model = "Primary unweighted binary logistic regression: HbA1c diabetes vs not diabetes",
  analytic_sample_n = nrow(analysis_data), complete_case_n = nrow(model_data),
  excluded_for_missingness_n = nrow(analysis_data) - nrow(model_data),
  diabetes_events = sum(model_data$diabetes), pseudo_r_squared_mcfadden = round(1 - primary_model$deviance / primary_model$null.deviance, 3),
  weighting = "Unweighted", inference_scope = "Analytic-sample associations; not causal or nationally representative"
)

# Quantify HbA1c/self-report discordance as useful context, not as a model predictor.
classification_context <- analysis_data %>%
  count(diabetes_status, diabetes_self_report, name = "participants") %>%
  group_by(diabetes_status) %>% mutate(percent_within_hba1c_status = round(100 * participants / sum(participants), 1)) %>%
  ungroup()

write.csv(model_results, file.path(analysis_dir, "logistic_regression_results.csv"), row.names = FALSE)
write.csv(model_results, file.path(dashboard_dir, "dashboard_model_associations.csv"), row.names = FALSE)
write.csv(model_summary, file.path(analysis_dir, "model_summary.csv"), row.names = FALSE)
write.csv(classification_context, file.path(analysis_dir, "hba1c_self_report_context.csv"), row.names = FALSE)
saveRDS(primary_model, file.path(analysis_dir, "primary_logistic_model.rds"))

con <- dbConnect(SQLite(), file.path("Data", "database", "nhanes_diabetes.sqlite"))
dbWriteTable(con, "dashboard_model_associations", model_results, overwrite = TRUE)
dbWriteTable(con, "model_summary", model_summary, overwrite = TRUE)
dbDisconnect(con)
message("Primary logistic model completed with n=", nrow(model_data), "; events=", sum(model_data$diabetes), ".")
