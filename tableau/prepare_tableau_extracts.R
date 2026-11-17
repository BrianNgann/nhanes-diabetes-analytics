# Create presentation-oriented Tableau extracts from validated analysis outputs.
# This script does not recalculate prevalence estimates or regression results.

source_dir <- file.path("Data", "processed")
output_dir <- file.path("tableau", "data")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
format_half_up <- function(x, digits) {
  scale <- 10^digits
  formatC(floor(x * scale + 0.5) / scale, format = "f", digits = digits)
}

weighted_kpi <- read.csv(file.path(source_dir, "dashboard_tables", "dashboard_survey_weighted_kpi.csv"), check.names = FALSE)
prevalence_comparison <- read.csv(file.path(source_dir, "analysis", "weighted_unweighted_prevalence_comparison.csv"), check.names = FALSE)
weighted_groups <- read.csv(file.path(source_dir, "dashboard_tables", "dashboard_survey_weighted_group_prevalence.csv"), check.names = FALSE)
weighted_model <- read.csv(file.path(source_dir, "dashboard_tables", "dashboard_survey_weighted_model_associations.csv"), check.names = FALSE)

status_order <- c("Normal" = 1, "Prediabetes" = 2, "Diabetes" = 3)
burden <- merge(weighted_kpi, prevalence_comparison,
                by.x = "category", by.y = "diabetes_status", sort = FALSE)
burden$status_order <- unname(status_order[burden$category])
burden$observed_sample_n <- burden$unweighted_n.x
burden$observed_cases <- burden$unweighted_cases
burden$weighted_prevalence_percent <- burden$estimate
burden$weighted_ci_lower_percent <- burden$ci_lower
burden$weighted_ci_upper_percent <- burden$ci_upper
burden$unweighted_sample_percent <- burden$unweighted_percent
burden$estimate_scope <- "Survey-weighted U.S. civilian noninstitutionalized adults, NHANES August 2021-August 2023"
burden$count_scope <- "Observed analytic-sample count; not a population count"
burden$display_estimate <- paste0(format_half_up(burden$estimate, 1), "% (95% CI ",
                                  format_half_up(burden$ci_lower, 1), "-",
                                  format_half_up(burden$ci_upper, 1), "%)")
burden <- burden[order(burden$status_order), c(
  "status_order", "category", "weighted_prevalence_percent", "weighted_ci_lower_percent",
  "weighted_ci_upper_percent", "unweighted_sample_percent", "percentage_point_difference",
  "observed_sample_n", "observed_cases", "display_estimate", "estimate_type",
  "weight_variable", "estimate_scope", "count_scope")]

dimension_order <- c("Age group"=1, "BMI category"=2, "Sex"=3,
                     "Race/ethnicity"=4, "Education"=5, "Income group"=6)
group_orders <- list(
  "Age group"=c("20-39","40-59","60+"),
  "BMI category"=c("Underweight","Normal","Overweight","Obese"),
  "Sex"=c("Female","Male"),
  "Race/ethnicity"=c("Mexican American","Other Hispanic","Non-Hispanic White","Non-Hispanic Black","Non-Hispanic Asian","Other Race"),
  "Education"=c("Less than 9th Grade","9th-11th Grade","High School/GED","Some College/AA","College Graduate"),
  "Income group"=c("Below poverty","1.00-1.99","2.00-2.99","3.00-4.99","5.00+"))
weighted_groups$dimension_order <- unname(dimension_order[weighted_groups$dimension])
weighted_groups$group_order <- mapply(function(d, g) match(g, group_orders[[d]]), weighted_groups$dimension, weighted_groups$group)
weighted_groups$outcome_order <- ifelse(weighted_groups$category == "Diabetes", 1, 2)
weighted_groups$ci_width <- weighted_groups$ci_upper - weighted_groups$ci_lower
weighted_groups$use_caution <- weighted_groups$reliability_flag == "Use caution"
weighted_groups$display_estimate <- paste0(format_half_up(weighted_groups$estimate, 1), "% (95% CI ",
                                           format_half_up(weighted_groups$ci_lower, 1), "-",
                                           format_half_up(weighted_groups$ci_upper, 1), "%)")
weighted_groups$observed_n_label <- paste0("Observed subgroup n = ", format(weighted_groups$unweighted_n, big.mark=","))
weighted_groups$estimate_scope <- "Survey-weighted prevalence; observed n is not a weighted population count"
weighted_groups <- weighted_groups[order(weighted_groups$dimension_order, weighted_groups$group_order, weighted_groups$outcome_order), ]

role_order <- c("Targeting: demographic"=1, "Targeting: socioeconomic"=2,
                "Intervention planning: modifiable clinical"=3,
                "Intervention planning: modifiable lifestyle"=4)
weighted_model$role_order <- unname(role_order[weighted_model$factor_role])
weighted_model$ci_crosses_one <- weighted_model$ci_lower <= 1 & weighted_model$ci_upper >= 1
weighted_model$association_signal <- ifelse(weighted_model$ci_crosses_one, "CI includes 1", "CI excludes 1")
weighted_model$display_or <- paste0("OR ", format_half_up(weighted_model$odds_ratio, 2),
                                    " (95% CI ", format_half_up(weighted_model$ci_lower, 2), "-",
                                    format_half_up(weighted_model$ci_upper, 2), ")")
weighted_model$comparison_order <- ave(-weighted_model$odds_ratio, weighted_model$role_order,
                                       FUN = function(x) rank(x, ties.method = "first"))
weighted_model$inference_note <- "Survey-adjusted association; observational and not causal"
weighted_model <- weighted_model[order(weighted_model$role_order, weighted_model$comparison_order), ]

write.csv(burden, file.path(output_dir, "tableau_diabetes_burden.csv"), row.names = FALSE, na = "")
write.csv(weighted_groups, file.path(output_dir, "tableau_subgroup_prevalence.csv"), row.names = FALSE, na = "")
write.csv(weighted_model, file.path(output_dir, "tableau_adjusted_associations.csv"), row.names = FALSE, na = "")

message("Created three Tableau extracts from existing validated outputs.")
