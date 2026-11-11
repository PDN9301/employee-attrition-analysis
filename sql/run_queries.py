"""Run every query in attrition_queries.sql, save each result to sql/results/,
and export the employee-level Tableau extract to tableau/.

Usage:  python sql/load_data.py      (once, builds hr.db)
        python sql/run_queries.py
"""
import re
import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = ROOT / "sql"
RESULTS_DIR = SQL_DIR / "results"
TABLEAU_DIR = ROOT / "tableau"


def named_queries(sql_text):
    """Split a .sql file on '-- name: <query_name>' markers."""
    parts = re.split(r"^-- name:\s*(\S+)\s*$", sql_text, flags=re.M)
    return dict(zip(parts[1::2], (p.strip() for p in parts[2::2])))


def main():
    RESULTS_DIR.mkdir(exist_ok=True)
    TABLEAU_DIR.mkdir(exist_ok=True)

    with sqlite3.connect(SQL_DIR / "hr.db") as conn:
        queries = named_queries((SQL_DIR / "attrition_queries.sql").read_text(encoding="utf-8"))
        for name, query in queries.items():
            result = pd.read_sql_query(query, conn)
            result.to_csv(RESULTS_DIR / f"{name}.csv", index=False)
            question = re.search(r"^-- Q:\s*(.+)$", query, flags=re.M).group(1)
            print(f"\n## {name}\n{question}\n")
            print(result.to_string(index=False))

        extract = pd.read_sql_query((SQL_DIR / "tableau_extract.sql").read_text(encoding="utf-8"), conn)
        extract.to_csv(TABLEAU_DIR / "employee_attrition_tableau.csv", index=False)
        print(f"\nTableau extract: {len(extract):,} rows -> tableau/employee_attrition_tableau.csv")


if __name__ == "__main__":
    main()
