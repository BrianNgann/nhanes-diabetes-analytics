# Export the cleaned analytic dataset to SQLite.

library(DBI)
library(RSQLite)

if (!exists("analysis_data", inherits = FALSE) || !is.data.frame(analysis_data)) {
  source(file.path("R", "02_clean_transform.R"))
}

database_dir <- file.path("Data", "database")
dir.create(database_dir, showWarnings = FALSE, recursive = TRUE)

database_path <- file.path(database_dir, "nhanes_diabetes.sqlite")
con <- dbConnect(RSQLite::SQLite(), database_path)

dbWriteTable(
  con,
  "nhanes_diabetes",
  analysis_data,
  overwrite = TRUE
)

dbDisconnect(con)

message("Wrote SQLite database to ", normalizePath(database_path))
