# Validate every published artifact and guard against stale/empty outputs.
suppressPackageStartupMessages({library(DBI); library(RSQLite)})
required_files <- c(
  file.path("Data", "processed", "nhanes_diabetes_analysis.csv"),
  file.path("Data", "database", "nhanes_diabetes.sqlite"),
  file.path("Data", "processed", "dashboard_tables", "dashboard_kpi.csv"),
  file.path("Data", "processed", "dashboard_tables", "dashboard_dimension_burden.csv"),
  file.path("Data", "processed", "dashboard_tables", "dashboard_priority_segments.csv"),
  file.path("Data", "processed", "dashboard_tables", "dashboard_model_associations.csv"),
  file.path("Data", "processed", "analysis", "model_summary.csv"),
  file.path("Data", "processed", "dashboard_tables", "dashboard_survey_weighted_kpi.csv"),
  file.path("Data", "processed", "dashboard_tables", "dashboard_survey_weighted_group_prevalence.csv"),
  file.path("Data", "processed", "dashboard_tables", "dashboard_survey_weighted_model_associations.csv"),
  file.path("Data", "processed", "analysis", "survey_design_summary.csv"))
bad <- required_files[!file.exists(required_files) | file.info(required_files)$size == 0]
if (length(bad)) stop("Missing or empty output(s): ", paste(bad, collapse = ", "))

csv <- read.csv(required_files[1])
if (anyDuplicated(csv$SEQN) || any(csv$age < 20) || anyNA(csv$diabetes_status)) stop("Final CSV validation failed.")
if (anyNA(csv$phlebotomy_weight) || any(csv$phlebotomy_weight <= 0) ||
    anyNA(csv$survey_stratum) || anyNA(csv$survey_psu)) stop("Final survey-design validation failed.")
weighted_kpi <- read.csv(file.path("Data", "processed", "dashboard_tables", "dashboard_survey_weighted_kpi.csv"))
weighted_model <- read.csv(file.path("Data", "processed", "dashboard_tables", "dashboard_survey_weighted_model_associations.csv"))
if (anyNA(weighted_kpi[, c("estimate", "ci_lower", "ci_upper")]) ||
    abs(sum(weighted_kpi$estimate) - 100) > 0.1) stop("Weighted prevalence validation failed.")
if (anyNA(weighted_model[, c("odds_ratio", "ci_lower", "ci_upper", "p_value")])) stop("Weighted model inference is incomplete.")
con <- dbConnect(SQLite(), required_files[2])
if (dbGetQuery(con, "SELECT COUNT(*) n, COUNT(DISTINCT SEQN) unique_n FROM nhanes_diabetes")$n != nrow(csv)) stop("CSV/database row counts differ.")
if (dbGetQuery(con, "SELECT COUNT(*) n FROM dashboard_model_associations")$n < 1) stop("Model results missing from SQLite.")
if (dbGetQuery(con, "SELECT COUNT(*) n FROM dashboard_survey_weighted_model_associations")$n < 1) stop("Survey model results missing from SQLite.")
dbDisconnect(con)
message("Final validation passed: ", nrow(csv), " unique eligible participants and all outputs populated.")
