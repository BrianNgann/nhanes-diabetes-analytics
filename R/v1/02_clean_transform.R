# Clean, merge, and transform NHANES data for diabetes risk analysis.

library(dplyr)

if (!exists("demo", inherits = FALSE) || !is.data.frame(demo)) {
  source(file.path("R", "01_load_data.R"))
}

processed_dir <- file.path("Data", "processed")
dir.create(processed_dir, showWarnings = FALSE, recursive = TRUE)

demo_selected <- demo %>%
  select(
    SEQN,
    RIAGENDR,
    RIDAGEYR,
    RIDRETH3,
    DMDEDUC2,
    INDFMPIR
  )

bmx_selected <- bmx %>%
  select(SEQN, BMXWT, BMXHT, BMXBMI, BMXWAIST)

bpxo_selected <- bpxo %>%
  select(SEQN, BPXOSY1, BPXODI1)

diq_selected <- diq %>%
  select(SEQN, DIQ010)

ghb_selected <- ghb %>%
  select(SEQN, LBXGH)

glu_selected <- glu %>%
  select(SEQN, LBXGLU)

tchol_selected <- tchol %>%
  select(SEQN, LBXTC)

hdl_selected <- hdl %>%
  select(SEQN, LBDHDD)

smq_selected <- smq %>%
  select(SEQN, SMQ020)

paq_selected <- paq %>%
  select(SEQN, PAD800)

slq_selected <- slq %>%
  select(SEQN, SLD012)

alq_selected <- alq %>%
  select(SEQN, ALQ121)

nhanes <- demo_selected %>%
  left_join(bmx_selected, by = "SEQN") %>%
  left_join(bpxo_selected, by = "SEQN") %>%
  left_join(diq_selected, by = "SEQN") %>%
  left_join(ghb_selected, by = "SEQN") %>%
  left_join(glu_selected, by = "SEQN") %>%
  left_join(tchol_selected, by = "SEQN") %>%
  left_join(hdl_selected, by = "SEQN") %>%
  left_join(smq_selected, by = "SEQN") %>%
  left_join(paq_selected, by = "SEQN") %>%
  left_join(slq_selected, by = "SEQN") %>%
  left_join(alq_selected, by = "SEQN")

nhanes_clean <- nhanes %>%
  mutate(
    sex = case_when(
      RIAGENDR == 1 ~ "Male",
      RIAGENDR == 2 ~ "Female",
      TRUE ~ NA_character_
    ),
    diabetes_self_report = case_when(
      DIQ010 == 1 ~ "Yes",
      DIQ010 == 2 ~ "No",
      DIQ010 == 3 ~ "Borderline",
      TRUE ~ NA_character_
    ),
    smoking_status = case_when(
      SMQ020 == 1 ~ "Ever Smoked",
      SMQ020 == 2 ~ "Never Smoked",
      TRUE ~ NA_character_
    ),
    race_ethnicity = case_when(
      RIDRETH3 == 1 ~ "Mexican American",
      RIDRETH3 == 2 ~ "Other Hispanic",
      RIDRETH3 == 3 ~ "Non-Hispanic White",
      RIDRETH3 == 4 ~ "Non-Hispanic Black",
      RIDRETH3 == 6 ~ "Non-Hispanic Asian",
      RIDRETH3 == 7 ~ "Other Race",
      TRUE ~ NA_character_
    ),
    education = case_when(
      DMDEDUC2 == 1 ~ "Less than 9th Grade",
      DMDEDUC2 == 2 ~ "9th-11th Grade",
      DMDEDUC2 == 3 ~ "High School/GED",
      DMDEDUC2 == 4 ~ "Some College/AA",
      DMDEDUC2 == 5 ~ "College Graduate",
      TRUE ~ NA_character_
    ),
    age_group = case_when(
      RIDAGEYR >= 20 & RIDAGEYR <= 39 ~ "20-39",
      RIDAGEYR >= 40 & RIDAGEYR <= 59 ~ "40-59",
      RIDAGEYR >= 60 ~ "60+",
      TRUE ~ NA_character_
    ),
    bmi_category = case_when(
      BMXBMI < 18.5 ~ "Underweight",
      BMXBMI < 25 ~ "Normal",
      BMXBMI < 30 ~ "Overweight",
      BMXBMI >= 30 ~ "Obese",
      TRUE ~ NA_character_
    ),
    diabetes_status = case_when(
      LBXGH < 5.7 ~ "Normal",
      LBXGH < 6.5 ~ "Prediabetes",
      LBXGH >= 6.5 ~ "Diabetes",
      TRUE ~ NA_character_
    )
  )

analysis_data <- nhanes_clean %>%
  filter(RIDAGEYR >= 20, !is.na(diabetes_status)) %>%
  transmute(
    SEQN,
    age = RIDAGEYR,
    sex,
    race_ethnicity,
    education,
    income_ratio = INDFMPIR,
    age_group,
    bmi = BMXBMI,
    bmi_category,
    waist = BMXWAIST,
    systolic_bp = BPXOSY1,
    diastolic_bp = BPXODI1,
    hba1c = LBXGH,
    glucose = LBXGLU,
    cholesterol = LBXTC,
    hdl = LBDHDD,
    sleep_hours = SLD012,
    smoking_status,
    physical_activity_minutes = PAD800,
    alcohol_frequency = ALQ121,
    diabetes_self_report,
    diabetes_status
  ) %>%
  mutate(
    diabetes_status = factor(
      diabetes_status,
      levels = c("Normal", "Prediabetes", "Diabetes")
    ),
    bmi_category = factor(
      bmi_category,
      levels = c("Underweight", "Normal", "Overweight", "Obese")
    ),
    age_group = factor(age_group, levels = c("20-39", "40-59", "60+"))
  )

analysis_csv <- file.path(processed_dir, "nhanes_diabetes_analysis.csv")
write.csv(analysis_data, analysis_csv, row.names = FALSE)

message("Wrote clean analytic CSV to ", normalizePath(analysis_csv))
message("Final analytic sample size: ", nrow(analysis_data))
