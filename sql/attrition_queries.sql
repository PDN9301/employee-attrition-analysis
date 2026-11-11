-- =====================================================================
-- Employee Attrition Analysis: SQL
-- Database: SQLite (hr.db, built by load_data.py)
-- Each query starts with "-- name:" so run_queries.py can run and export it.
-- =====================================================================


-- name: 01_overall_attrition
-- Q: What is the company-wide attrition rate?
SELECT
    COUNT(*)                                  AS headcount,
    SUM(left_company)                         AS employees_left,
    ROUND(100.0 * AVG(left_company), 1)       AS attrition_rate_pct,
    ROUND(AVG(satisfaction_level), 2)         AS avg_satisfaction
FROM employees;


-- name: 02_attrition_by_department
-- Q: Which departments lose the most people, and how do they compare to the company average?
SELECT
    department,
    COUNT(*)                                                        AS headcount,
    SUM(left_company)                                               AS employees_left,
    ROUND(100.0 * AVG(left_company), 1)                             AS attrition_rate_pct,
    ROUND(100.0 * (AVG(left_company)
          - (SELECT AVG(left_company) FROM employees)), 1)          AS vs_company_avg_pts,
    RANK() OVER (ORDER BY AVG(left_company) DESC)                   AS attrition_rank,
    ROUND(100.0 * SUM(left_company) / SUM(SUM(left_company)) OVER (), 1) AS share_of_all_leavers_pct
FROM employees
GROUP BY department
ORDER BY attrition_rate_pct DESC;


-- name: 03_attrition_by_salary
-- Q: Does pay level affect attrition? (JOIN to the lookup table for correct low -> high order)
SELECT
    e.salary_level,
    COUNT(*)                              AS headcount,
    SUM(e.left_company)                   AS employees_left,
    ROUND(100.0 * AVG(e.left_company), 1) AS attrition_rate_pct
FROM employees AS e
JOIN salary_levels AS s
    ON s.salary_level = e.salary_level
GROUP BY e.salary_level, s.salary_rank
ORDER BY s.salary_rank;


-- name: 04_attrition_by_workload
-- Q: How does the number of projects relate to hours worked and attrition?
SELECT
    number_projects,
    COUNT(*)                              AS headcount,
    CAST(ROUND(AVG(avg_monthly_hours)) AS INTEGER)      AS avg_monthly_hours,
    ROUND(AVG(satisfaction_level), 2)     AS avg_satisfaction,
    ROUND(100.0 * AVG(left_company), 1)   AS attrition_rate_pct
FROM employees
GROUP BY number_projects
ORDER BY number_projects;


-- name: 05_attrition_by_tenure
-- Q: At what point in their tenure are employees most likely to leave?
SELECT
    years_at_company,
    COUNT(*)                              AS headcount,
    SUM(left_company)                     AS employees_left,
    ROUND(100.0 * AVG(left_company), 1)   AS attrition_rate_pct
FROM employees
GROUP BY years_at_company
ORDER BY years_at_company;


-- name: 06_leaver_segments
-- Q: What kinds of employees are leaving? (rule-based version of the K-Means clusters in the notebook)
WITH segmented AS (
    SELECT
        *,
        CASE
            WHEN last_evaluation >= 0.75 AND satisfaction_level <  0.20 THEN 'Burned-out high performer'
            WHEN last_evaluation <  0.60 AND satisfaction_level BETWEEN 0.30 AND 0.50 THEN 'Disengaged under-performer'
            WHEN last_evaluation >= 0.75 AND satisfaction_level >= 0.70 THEN 'Satisfied high performer'
            ELSE 'Other'
        END AS segment
    FROM employees
)
SELECT
    segment,
    COUNT(*)                                                         AS headcount,
    SUM(left_company)                                                AS employees_left,
    ROUND(100.0 * AVG(left_company), 1)                              AS attrition_rate_pct,
    ROUND(100.0 * SUM(left_company) / SUM(SUM(left_company)) OVER (), 1) AS share_of_all_leavers_pct,
    CAST(ROUND(AVG(avg_monthly_hours)) AS INTEGER)                                 AS avg_monthly_hours,
    ROUND(AVG(number_projects), 1)                                   AS avg_projects
FROM segmented
GROUP BY segment
ORDER BY employees_left DESC;


-- name: 07_overwork_risk
-- Q: Are overworked employees (6+ projects or 250+ hours/month) leaving at higher rates?
SELECT
    CASE
        WHEN number_projects >= 6 OR avg_monthly_hours >= 250 THEN 'Overworked'
        WHEN number_projects <= 2 AND avg_monthly_hours < 160  THEN 'Under-utilized'
        ELSE 'Balanced'
    END                                   AS workload_group,
    COUNT(*)                              AS headcount,
    SUM(left_company)                     AS employees_left,
    ROUND(100.0 * AVG(left_company), 1)   AS attrition_rate_pct
FROM employees
GROUP BY workload_group
ORDER BY attrition_rate_pct DESC;


-- name: 08_promotion_effect
-- Q: Do promotions help retention?
SELECT
    CASE promoted_last_5yrs WHEN 1 THEN 'Promoted' ELSE 'Not promoted' END AS promotion_status,
    COUNT(*)                              AS headcount,
    ROUND(100.0 * AVG(left_company), 1)   AS attrition_rate_pct
FROM employees
GROUP BY promoted_last_5yrs
ORDER BY attrition_rate_pct DESC;


-- name: 09_high_performer_flight_by_department
-- Q: Which departments are losing their best people faster than the company average?
WITH high_performers AS (
    SELECT department, left_company
    FROM employees
    WHERE last_evaluation >= 0.80
),
dept_rates AS (
    SELECT
        department,
        COUNT(*)            AS high_performers,
        SUM(left_company)   AS high_performers_left,
        AVG(left_company)   AS rate
    FROM high_performers
    GROUP BY department
),
company AS (
    SELECT AVG(left_company) AS rate FROM high_performers
)
SELECT
    d.department,
    d.high_performers,
    d.high_performers_left,
    ROUND(100.0 * d.rate, 1)              AS hp_attrition_rate_pct,
    ROUND(100.0 * c.rate, 1)              AS company_hp_attrition_rate_pct,
    ROUND(100.0 * (d.rate - c.rate), 1)   AS vs_company_pts
FROM dept_rates AS d
CROSS JOIN company AS c
WHERE d.rate > c.rate
ORDER BY hp_attrition_rate_pct DESC;


-- name: 10_department_salary_matrix
-- Q: Where do department and pay combine into the highest attrition? (feeds a heat map)
SELECT
    e.department,
    e.salary_level,
    COUNT(*)                              AS headcount,
    ROUND(100.0 * AVG(e.left_company), 1) AS attrition_rate_pct
FROM employees AS e
JOIN salary_levels AS s
    ON s.salary_level = e.salary_level
GROUP BY e.department, e.salary_level, s.salary_rank
HAVING COUNT(*) >= 30          -- ignore tiny groups
ORDER BY attrition_rate_pct DESC
LIMIT 10;
