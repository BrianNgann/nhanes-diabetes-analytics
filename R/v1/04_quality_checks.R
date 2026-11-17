# Run basic quality checks on the cleaned NHANES diabetes dataset.

library(dplyr)

if (!exists("analysis_data", inherits = FALSE) || !is.data.frame(analysis_data)) {
  source(file.path("R", "02_clean_transform.R"))
}

required_columns <- c(
  "SEQN",
  "age",
  "sex",
  "race_ethnicity",
  "education",
  "income_ratio",
  "age_group",
  "bmi",
  "bmi_category",
  "waist",
  "systolic_bp",
  "diastolic_bp",
  "hba1c",
  "glucose",
  "cholesterol",
  "hdl",
  "sleep_hours",
  "smoking_status",
  "physical_activity_minutes",
  "alcohol_frequency",
  "diabetes_self_report",
  "diabetes_status"
)

missing_columns <- setdiff(required_columns, names(analysis_data))

if (length(missing_columns) > 0) {
  stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
}

if (anyDuplicated(analysis_data$SEQN) > 0) {
  stop("SEQN should be unique in the analytic dataset.")
}

if (any(analysis_data$age < 20, na.rm = TRUE)) {
  stop("Analytic dataset contains respondents under age 20.")
}

if (any(is.na(analysis_data$diabetes_status))) {
  stop("Analytic dataset contains missing diabetes status.")
}

status_counts <- analysis_data %>%
  count(diabetes_status, name = "participants")

missing_summary <- analysis_data %>%
  summarise(across(everything(), ~ sum(is.na(.x)))) %>%
  tidyr::pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "missing_count"
  ) %>%
  arrange(desc(missing_count))

print(status_counts)
print(head(missing_summary, 10))

message("Quality checks passed.")
