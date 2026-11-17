# Create dashboard-ready SQL views and export them as CSV files.

library(DBI)
library(RSQLite)

database_path <- file.path("Data", "database", "nhanes_diabetes.sqlite")
dashboard_dir <- file.path("Data", "processed", "dashboard_tables")

dir.create(dashboard_dir, showWarnings = FALSE, recursive = TRUE)

if (!file.exists(database_path)) {
  source(file.path("R", "03_export_database.R"))
}

con <- dbConnect(RSQLite::SQLite(), database_path)

dbExecute(con, "DROP VIEW IF EXISTS vw_kpi_overview")
dbExecute(con, "
  CREATE VIEW vw_kpi_overview AS
  SELECT
    COUNT(*) AS adult_participants,
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(AVG(bmi), 1) AS avg_bmi,
    ROUND(AVG(hba1c), 2) AS avg_hba1c,
    ROUND(100.0 * AVG(CASE WHEN diabetes_status = 'Prediabetes' THEN 1 ELSE 0 END), 1) AS prediabetes_rate,
    ROUND(100.0 * AVG(CASE WHEN diabetes_status = 'Diabetes' THEN 1 ELSE 0 END), 1) AS diabetes_rate
  FROM nhanes_diabetes
")

dbExecute(con, "DROP VIEW IF EXISTS vw_status_distribution")
dbExecute(con, "
  CREATE VIEW vw_status_distribution AS
  SELECT
    diabetes_status,
    COUNT(*) AS participants,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percent_of_sample
  FROM nhanes_diabetes
  GROUP BY diabetes_status
")

dbExecute(con, "DROP VIEW IF EXISTS vw_age_bmi_risk_segments")
dbExecute(con, "
  CREATE VIEW vw_age_bmi_risk_segments AS
  SELECT
    age_group,
    bmi_category,
    COUNT(*) AS participants,
    ROUND(100.0 * AVG(CASE WHEN diabetes_status = 'Diabetes' THEN 1 ELSE 0 END), 1) AS diabetes_rate,
    ROUND(100.0 * AVG(CASE WHEN diabetes_status IN ('Prediabetes', 'Diabetes') THEN 1 ELSE 0 END), 1) AS elevated_risk_rate,
    ROUND(AVG(hba1c), 2) AS avg_hba1c,
    ROUND(AVG(glucose), 1) AS avg_glucose,
    ROUND(AVG(bmi), 1) AS avg_bmi
  FROM nhanes_diabetes
  WHERE age_group IS NOT NULL
    AND bmi_category IS NOT NULL
  GROUP BY age_group, bmi_category
  HAVING COUNT(*) >= 30
")

dbExecute(con, "DROP VIEW IF EXISTS vw_demographic_risk")
dbExecute(con, "
  CREATE VIEW vw_demographic_risk AS
  SELECT
    race_ethnicity,
    education,
    COUNT(*) AS participants,
    ROUND(100.0 * AVG(CASE WHEN diabetes_status = 'Prediabetes' THEN 1 ELSE 0 END), 1) AS prediabetes_rate,
    ROUND(100.0 * AVG(CASE WHEN diabetes_status = 'Diabetes' THEN 1 ELSE 0 END), 1) AS diabetes_rate,
    ROUND(AVG(income_ratio), 2) AS avg_income_ratio,
    ROUND(AVG(hba1c), 2) AS avg_hba1c
  FROM nhanes_diabetes
  WHERE race_ethnicity IS NOT NULL
    AND education IS NOT NULL
  GROUP BY race_ethnicity, education
")

dashboard_views <- c(
  "vw_kpi_overview",
  "vw_status_distribution",
  "vw_age_bmi_risk_segments",
  "vw_demographic_risk"
)

for (view_name in dashboard_views) {
  output_path <- file.path(dashboard_dir, paste0(view_name, ".csv"))
  write.csv(dbReadTable(con, view_name), output_path, row.names = FALSE)
  message("Wrote dashboard table to ", normalizePath(output_path))
}

dbDisconnect(con)

message("Dashboard table export completed successfully.")
