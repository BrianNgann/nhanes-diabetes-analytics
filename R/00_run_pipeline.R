# Run the portfolio-quality workflow from the project root.
# The original numbered scripts remain available as the legacy implementation.
options(warn = 1)
stages <- c(
  file.path("R", "v2", "01_prepare_analysis_data.R"),
  file.path("R", "v2", "02_validate_analysis_data.R"),
  file.path("R", "v2", "03_publish_database.R"),
  file.path("R", "v2", "04_build_descriptive_views.R"),
  file.path("R", "analysis", "01_descriptive_and_logistic_model.R"),
  file.path("R", "analysis", "02_survey_weighted_analysis.R"),
  file.path("R", "v2", "05_final_validation.R")
)
for (stage in stages) {
  message("\n--- Running ", stage, " ---")
  source(stage, local = globalenv(), echo = FALSE)
}
message("\nPipeline completed successfully.")
