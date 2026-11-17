-- Portfolio dashboard views. All percentages are unweighted analytic-sample estimates.
DROP VIEW IF EXISTS dashboard_kpi;
CREATE VIEW dashboard_kpi AS
SELECT COUNT(*) AS participants,
 ROUND(100.0*AVG(diabetes_status='Normal'),1) AS normal_percent,
 ROUND(100.0*AVG(diabetes_status='Prediabetes'),1) AS prediabetes_percent,
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1) AS diabetes_percent,
 ROUND(AVG(hba1c),2) AS average_hba1c,
 'Unweighted analytic sample - not nationally representative' AS estimate_scope
FROM nhanes_diabetes;

DROP VIEW IF EXISTS dashboard_status_distribution;
CREATE VIEW dashboard_status_distribution AS
SELECT diabetes_status, COUNT(*) AS participants,
 ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM nhanes_diabetes),1) AS sample_percent
FROM nhanes_diabetes GROUP BY diabetes_status;

DROP VIEW IF EXISTS dashboard_dimension_burden;
CREATE VIEW dashboard_dimension_burden AS
SELECT 'Age group' AS dimension, age_group AS category, COUNT(*) AS participants,
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1) AS diabetes_percent,
 ROUND(100.0*AVG(diabetes_status='Prediabetes'),1) AS prediabetes_percent
FROM nhanes_diabetes WHERE age_group IS NOT NULL GROUP BY age_group
UNION ALL SELECT 'BMI category', bmi_category, COUNT(*),
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1), ROUND(100.0*AVG(diabetes_status='Prediabetes'),1)
FROM nhanes_diabetes WHERE bmi_category IS NOT NULL GROUP BY bmi_category
UNION ALL SELECT 'Race/ethnicity', race_ethnicity, COUNT(*),
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1), ROUND(100.0*AVG(diabetes_status='Prediabetes'),1)
FROM nhanes_diabetes WHERE race_ethnicity IS NOT NULL GROUP BY race_ethnicity
UNION ALL SELECT 'Education', education, COUNT(*),
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1), ROUND(100.0*AVG(diabetes_status='Prediabetes'),1)
FROM nhanes_diabetes WHERE education IS NOT NULL GROUP BY education
UNION ALL SELECT 'Income group', income_group, COUNT(*),
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1), ROUND(100.0*AVG(diabetes_status='Prediabetes'),1)
FROM nhanes_diabetes WHERE income_group IS NOT NULL GROUP BY income_group
UNION ALL SELECT 'Sex', sex, COUNT(*),
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1), ROUND(100.0*AVG(diabetes_status='Prediabetes'),1)
FROM nhanes_diabetes WHERE sex IS NOT NULL GROUP BY sex
UNION ALL SELECT 'Smoking history', smoking_status, COUNT(*),
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1), ROUND(100.0*AVG(diabetes_status='Prediabetes'),1)
FROM nhanes_diabetes WHERE smoking_status IS NOT NULL GROUP BY smoking_status
UNION ALL SELECT 'Sleep duration', sleep_group, COUNT(*),
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1), ROUND(100.0*AVG(diabetes_status='Prediabetes'),1)
FROM nhanes_diabetes WHERE sleep_group IS NOT NULL GROUP BY sleep_group
UNION ALL SELECT 'Moderate LTPA session duration', activity_duration_group, COUNT(*),
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1), ROUND(100.0*AVG(diabetes_status='Prediabetes'),1)
FROM nhanes_diabetes WHERE activity_duration_group IS NOT NULL GROUP BY activity_duration_group
UNION ALL SELECT 'Alcohol frequency', alcohol_frequency_group, COUNT(*),
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1), ROUND(100.0*AVG(diabetes_status='Prediabetes'),1)
FROM nhanes_diabetes WHERE alcohol_frequency_group IS NOT NULL GROUP BY alcohol_frequency_group;

DROP VIEW IF EXISTS dashboard_age_bmi_segments;
CREATE VIEW dashboard_age_bmi_segments AS
SELECT age_group, bmi_category, COUNT(*) AS participants,
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1) AS diabetes_percent,
 ROUND(100.0*AVG(diabetes_status='Prediabetes'),1) AS prediabetes_percent,
 ROUND(100.0*AVG(diabetes_status IN ('Prediabetes','Diabetes')),1) AS elevated_percent
FROM nhanes_diabetes WHERE age_group IS NOT NULL AND bmi_category IS NOT NULL
GROUP BY age_group, bmi_category HAVING COUNT(*) >= 30;

DROP VIEW IF EXISTS dashboard_priority_segments;
CREATE VIEW dashboard_priority_segments AS
SELECT age_group, bmi_category, COUNT(*) AS participants,
 ROUND(100.0*AVG(diabetes_status='Diabetes'),1) AS diabetes_percent,
 ROUND(100.0*AVG(diabetes_status='Prediabetes'),1) AS prediabetes_percent,
 RANK() OVER (ORDER BY AVG(diabetes_status='Diabetes') DESC) AS burden_rank,
 'Age is useful for targeting. BMI is potentially modifiable and useful for intervention planning.' AS interpretation
FROM nhanes_diabetes WHERE age_group IS NOT NULL AND bmi_category IS NOT NULL
GROUP BY age_group, bmi_category HAVING COUNT(*) >= 100;
