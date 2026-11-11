"""Load the HR dataset into a SQLite database (hr.db) with clean column names.

Usage:  python sql/load_data.py
"""
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "sql" / "hr.db"

# Rename the raw columns to clearer, consistent names (and fix the 'montly' typo)
COLUMNS = {
    "satisfaction_level": "satisfaction_level",
    "last_evaluation": "last_evaluation",
    "number_project": "number_projects",
    "average_montly_hours": "avg_monthly_hours",
    "time_spend_company": "years_at_company",
    "Work_accident": "work_accident",
    "left": "left_company",
    "promotion_last_5years": "promoted_last_5yrs",
    "sales": "department",
    "salary": "salary_level",
}

DEPARTMENTS = {
    "sales": "Sales", "accounting": "Accounting", "hr": "HR", "technical": "Technical",
    "support": "Support", "management": "Management", "IT": "IT",
    "product_mng": "Product Management", "marketing": "Marketing", "RandD": "R&D",
}

SCHEMA = """
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS salary_levels;

CREATE TABLE salary_levels (
    salary_level TEXT PRIMARY KEY,
    salary_rank  INTEGER NOT NULL      -- 1 = low, 2 = medium, 3 = high (for sorting)
);

CREATE TABLE employees (
    employee_id         INTEGER PRIMARY KEY,
    satisfaction_level  REAL    NOT NULL,   -- 0 to 1
    last_evaluation     REAL    NOT NULL,   -- 0 to 1
    number_projects     INTEGER NOT NULL,
    avg_monthly_hours   INTEGER NOT NULL,
    years_at_company    INTEGER NOT NULL,
    work_accident       INTEGER NOT NULL,   -- 1 = had a workplace accident
    left_company        INTEGER NOT NULL,   -- 1 = employee left
    promoted_last_5yrs  INTEGER NOT NULL,   -- 1 = promoted in last 5 years
    department          TEXT    NOT NULL,
    salary_level        TEXT    NOT NULL REFERENCES salary_levels (salary_level)
);
"""


def main():
    df = pd.read_csv(ROOT / "HR_comma_sep.csv").rename(columns=COLUMNS)
    df.insert(0, "employee_id", range(1, len(df) + 1))
    df["department"] = df["department"].map(DEPARTMENTS)

    with sqlite3.connect(DB_PATH) as conn:
        conn.executescript(SCHEMA)
        conn.executemany("INSERT INTO salary_levels VALUES (?, ?)", [("low", 1), ("medium", 2), ("high", 3)])
        df.to_sql("employees", conn, if_exists="append", index=False)
        count = conn.execute("SELECT COUNT(*) FROM employees").fetchone()[0]

    print(f"Loaded {count:,} employees into {DB_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
