# Fail before publication when cohort, key, category, or value rules are violated.
suppressPackageStartupMessages({library(dplyr); library(tidyr)})
if (!exists("analysis_data", inherits = FALSE)) source(file.path("R", "v2", "01_prepare_analysis_data.R"))

required <- c("SEQN", "age", "diabetes_status", "diabetes_binary", "hba1c",
              "phlebotomy_weight", "mec_exam_weight", "survey_stratum", "survey_psu")
missing_required <- setdiff(required, names(analysis_data))
if (length(missing_required)) stop("Required fields absent: ", paste(missing_required, collapse = ", "))
if (anyNA(analysis_data$SEQN) || anyDuplicated(analysis_data$SEQN)) stop("SEQN is missing or duplicated.")
if (any(analysis_data$age < 20) || anyNA(analysis_data$diabetes_status)) stop("Invalid analytic population.")
if (!all(analysis_data$diabetes_binary == (analysis_data$hba1c >= 6.5))) stop("Outcome does not match HbA1c rule.")
if (any(analysis_data$physical_activity_minutes > 780, na.rm = TRUE)) stop("Invalid PAD800 special code remains.")
if (any(!is.na(analysis_data$alcohol_frequency_code) &
        !(analysis_data$alcohol_frequency_code %in% 0:10))) stop("Invalid ALQ121 special code remains.")
if (!identical(analysis_data$SEQN, sort(analysis_data$SEQN))) stop("Output ordering is not deterministic.")
if (anyNA(analysis_data$phlebotomy_weight) || any(analysis_data$phlebotomy_weight <= 0)) stop("Eligible analytic records require positive WTPH2YR.")
if (anyNA(analysis_data$survey_stratum) || anyNA(analysis_data$survey_psu)) stop("Survey design fields are missing.")
if (any(table(analysis_data$survey_stratum, analysis_data$survey_psu) == 0)) stop("Expected two PSU codes within every represented stratum.")

quality_dir <- file.path("Data", "processed", "quality")
dir.create(quality_dir, recursive = TRUE, showWarnings = FALSE)
missingness <- analysis_data %>% summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
  mutate(total_rows = nrow(analysis_data), missing_percent = round(100 * missing_count / total_rows, 1)) %>%
  arrange(desc(missing_count), variable)
write.csv(missingness, file.path(quality_dir, "missingness_summary.csv"), row.names = FALSE)
write.csv(data.frame(check = c("eligible_adults", "unique_seqn", "outcome_complete", "raw_files_modified"),
                     result = c(nrow(analysis_data), !anyDuplicated(analysis_data$SEQN),
                                !anyNA(analysis_data$diabetes_status), FALSE)),
          file.path(quality_dir, "validation_results.csv"), row.names = FALSE)
message("Pre-publication validation passed.")
