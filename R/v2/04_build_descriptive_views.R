# Create SQL-backed descriptive views and export each view for Power BI.
suppressPackageStartupMessages({library(DBI); library(RSQLite)})
database_path <- file.path("Data", "database", "nhanes_diabetes.sqlite")
con <- dbConnect(SQLite(), database_path)
sql <- paste(readLines(file.path("sql", "06_portfolio_dashboard_views.sql"), warn = FALSE), collapse = "\n")
statements <- Filter(nzchar, trimws(strsplit(sql, ";", fixed = TRUE)[[1]]))
for (statement in statements) dbExecute(con, statement)

views <- c("dashboard_kpi", "dashboard_status_distribution", "dashboard_dimension_burden",
           "dashboard_age_bmi_segments", "dashboard_priority_segments")
out_dir <- file.path("Data", "processed", "dashboard_tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
for (view in views) {
  output <- dbGetQuery(con, paste("SELECT * FROM", view))
  if (!nrow(output)) stop("Dashboard view is empty: ", view)
  write.csv(output, file.path(out_dir, paste0(view, ".csv")), row.names = FALSE, na = "")
}
dbDisconnect(con)
message("Created and exported ", length(views), " SQL dashboard views.")
