# Build the portfolio-quality participant-level analytic dataset.
# Legacy scripts in R/01_load_data.R and R/02_clean_transform.R are retained for comparison.

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
})

data_dir <- "Data"
processed_dir <- file.path(data_dir, "processed")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)

read_component <- function(file_name) read_xpt(file.path(data_dir, file_name))
assert_unique_key <- function(data, component) {
  if (anyNA(data$SEQN) || anyDuplicated(data$SEQN)) {
    stop(component, " must contain one non-missing row per SEQN.")
  }
}

components <- list(
  demo = read_component("DEMO_L.xpt"), bmx = read_component("BMX_L.xpt"),
  bpxo = read_component("BPXO_L.xpt"), diq = read_component("DIQ_L.xpt"),
  ghb = read_component("GHB_L.xpt"), glu = read_component("GLU_L.xpt"),
  tchol = read_component("TCHOL_L.xpt"), hdl = read_component("HDL_L.xpt"),
  smq = read_component("SMQ_L.xpt"), paq = read_component("PAQ_L.xpt"),
  slq = read_component("SLQ_L.xpt"), alq = read_component("ALQ_L.xpt")
)
invisible(Map(assert_unique_key, components, names(components)))

analysis_data <- components$demo %>%
  select(SEQN, RIAGENDR, RIDAGEYR, RIDRETH3, DMDEDUC2, INDFMPIR,
         WTMEC2YR, SDMVSTRA, SDMVPSU) %>%
  left_join(select(components$bmx, SEQN, BMXBMI, BMXWAIST), by = "SEQN") %>%
  left_join(select(components$bpxo, SEQN, BPXOSY1, BPXODI1), by = "SEQN") %>%
  left_join(select(components$diq, SEQN, DIQ010), by = "SEQN") %>%
  left_join(select(components$ghb, SEQN, LBXGH, WTPH2YR), by = "SEQN") %>%
  left_join(select(components$glu, SEQN, LBXGLU, WTSAF2YR), by = "SEQN") %>%
  left_join(select(components$tchol, SEQN, LBXTC), by = "SEQN") %>%
  left_join(select(components$hdl, SEQN, LBDHDD), by = "SEQN") %>%
  left_join(select(components$smq, SEQN, SMQ020), by = "SEQN") %>%
  left_join(select(components$paq, SEQN, PAD800), by = "SEQN") %>%
  left_join(select(components$slq, SEQN, SLD012), by = "SEQN") %>%
  left_join(select(components$alq, SEQN, ALQ121), by = "SEQN") %>%
  filter(RIDAGEYR >= 20, !is.na(LBXGH)) %>%
  transmute(
    SEQN = as.integer(SEQN), age = RIDAGEYR,
    sex = case_when(RIAGENDR == 1 ~ "Male", RIAGENDR == 2 ~ "Female", TRUE ~ NA_character_),
    race_ethnicity = case_when(
      RIDRETH3 == 1 ~ "Mexican American", RIDRETH3 == 2 ~ "Other Hispanic",
      RIDRETH3 == 3 ~ "Non-Hispanic White", RIDRETH3 == 4 ~ "Non-Hispanic Black",
      RIDRETH3 == 6 ~ "Non-Hispanic Asian", RIDRETH3 == 7 ~ "Other Race",
      TRUE ~ NA_character_),
    education = case_when(
      DMDEDUC2 == 1 ~ "Less than 9th Grade", DMDEDUC2 == 2 ~ "9th-11th Grade",
      DMDEDUC2 == 3 ~ "High School/GED", DMDEDUC2 == 4 ~ "Some College/AA",
      DMDEDUC2 == 5 ~ "College Graduate", TRUE ~ NA_character_),
    income_ratio = INDFMPIR,
    income_group = case_when(
      INDFMPIR < 1 ~ "Below poverty", INDFMPIR < 2 ~ "1.00-1.99",
      INDFMPIR < 3 ~ "2.00-2.99", INDFMPIR < 5 ~ "3.00-4.99",
      INDFMPIR >= 5 ~ "5.00+", TRUE ~ NA_character_),
    age_group = case_when(age < 40 ~ "20-39", age < 60 ~ "40-59", TRUE ~ "60+"),
    bmi = BMXBMI,
    bmi_category = case_when(
      BMXBMI < 18.5 ~ "Underweight", BMXBMI < 25 ~ "Normal",
      BMXBMI < 30 ~ "Overweight", BMXBMI >= 30 ~ "Obese", TRUE ~ NA_character_),
    waist = BMXWAIST, systolic_bp = BPXOSY1, diastolic_bp = BPXODI1,
    hba1c = LBXGH, glucose = LBXGLU, cholesterol = LBXTC, hdl = LBDHDD,
    sleep_hours = if_else(SLD012 >= 2 & SLD012 <= 14, SLD012, NA_real_),
    sleep_group = case_when(
      sleep_hours < 6 ~ "Less than 6 hours", sleep_hours <= 8 ~ "6 to 8 hours",
      sleep_hours > 8 ~ "More than 8 hours", TRUE ~ NA_character_),
    smoking_status = case_when(SMQ020 == 1 ~ "Ever Smoked", SMQ020 == 2 ~ "Never Smoked", TRUE ~ NA_character_),
    physical_activity_minutes = if_else(PAD800 >= 1 & PAD800 <= 780, PAD800, NA_real_),
    activity_duration_group = case_when(
      physical_activity_minutes < 30 ~ "Less than 30 minutes",
      physical_activity_minutes < 60 ~ "30-59 minutes",
      physical_activity_minutes >= 60 ~ "60+ minutes", TRUE ~ NA_character_),
    alcohol_frequency_code = if_else(ALQ121 %in% 0:10, ALQ121, NA_real_),
    alcohol_frequency_group = case_when(
      ALQ121 == 0 ~ "None in past year", ALQ121 %in% 1:4 ~ "2+ times per week",
      ALQ121 %in% 5:7 ~ "Weekly to monthly", ALQ121 %in% 8:10 ~ "Less than monthly",
      TRUE ~ NA_character_),
    diabetes_self_report = case_when(
      DIQ010 == 1 ~ "Yes", DIQ010 == 2 ~ "No", DIQ010 == 3 ~ "Borderline", TRUE ~ NA_character_),
    diabetes_status = case_when(
      hba1c < 5.7 ~ "Normal", hba1c < 6.5 ~ "Prediabetes", TRUE ~ "Diabetes"),
    diabetes_binary = as.integer(diabetes_status == "Diabetes"),
    phlebotomy_weight = WTPH2YR, mec_exam_weight = WTMEC2YR,
    fasting_subsample_weight = WTSAF2YR,
    survey_stratum = SDMVSTRA, survey_psu = SDMVPSU
  ) %>%
  arrange(SEQN)

write.csv(analysis_data, file.path(processed_dir, "nhanes_diabetes_analysis.csv"),
          row.names = FALSE, na = "")
message("Prepared ", nrow(analysis_data), " eligible adults; raw XPT files were read only.")
