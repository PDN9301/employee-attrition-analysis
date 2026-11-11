-- =====================================================================
-- Tableau extract: one row per employee, with business-friendly labels
-- and derived bands so the dashboard needs few calculated fields.
-- Exported by run_queries.py to tableau/employee_attrition_tableau.csv
-- =====================================================================
SELECT
    e.employee_id                                       AS "Employee ID",
    e.department                                        AS "Department",
    UPPER(SUBSTR(e.salary_level, 1, 1)) || SUBSTR(e.salary_level, 2) AS "Salary Level",
    s.salary_rank                                       AS "Salary Rank",
    e.satisfaction_level                                AS "Satisfaction",
    e.last_evaluation                                   AS "Last Evaluation",
    e.number_projects                                   AS "Projects",
    e.avg_monthly_hours                                 AS "Avg Monthly Hours",
    e.years_at_company                                  AS "Years at Company",
    e.promoted_last_5yrs                                AS "Promoted Last 5 Yrs",
    e.work_accident                                     AS "Work Accident",
    e.left_company                                      AS "Left (1/0)",
    CASE e.left_company WHEN 1 THEN 'Left' ELSE 'Stayed' END AS "Status",

    CASE
        WHEN e.satisfaction_level < 0.20 THEN '1. Very low (<0.2)'
        WHEN e.satisfaction_level < 0.40 THEN '2. Low (0.2-0.4)'
        WHEN e.satisfaction_level < 0.60 THEN '3. Medium (0.4-0.6)'
        WHEN e.satisfaction_level < 0.80 THEN '4. High (0.6-0.8)'
        ELSE                                  '5. Very high (0.8+)'
    END                                                 AS "Satisfaction Band",

    CASE
        WHEN e.last_evaluation < 0.60 THEN '1. Low (<0.6)'
        WHEN e.last_evaluation < 0.75 THEN '2. Medium (0.6-0.75)'
        WHEN e.last_evaluation < 0.90 THEN '3. High (0.75-0.9)'
        ELSE                               '4. Very high (0.9+)'
    END                                                 AS "Evaluation Band",

    CASE
        WHEN e.number_projects >= 6 OR e.avg_monthly_hours >= 250 THEN 'Overworked'
        WHEN e.number_projects <= 2 AND e.avg_monthly_hours < 160  THEN 'Under-utilized'
        ELSE 'Balanced'
    END                                                 AS "Workload Group",

    CASE
        WHEN e.last_evaluation >= 0.75 AND e.satisfaction_level <  0.20 THEN 'Burned-out high performer'
        WHEN e.last_evaluation <  0.60 AND e.satisfaction_level BETWEEN 0.30 AND 0.50 THEN 'Disengaged under-performer'
        WHEN e.last_evaluation >= 0.75 AND e.satisfaction_level >= 0.70 THEN 'Satisfied high performer'
        ELSE 'Other'
    END                                                 AS "Segment"
FROM employees AS e
JOIN salary_levels AS s
    ON s.salary_level = e.salary_level
ORDER BY e.employee_id;
