"""
build_database.py
------------------
Builds a SQLite database (data/global_electronics.db) from the 5 raw CSVs,
so the analysis can also be run/reviewed in pure SQL (see sql/queries.sql).

Usage:
    python src/build_database.py
"""

import sqlite3
from pathlib import Path

from data_prep import (
    load_sales,
    load_products,
    load_customers,
    load_stores,
    load_exchange_rates,
)

DB_PATH = Path(__file__).resolve().parents[1] / "data" / "global_electronics.db"


def main():
    conn = sqlite3.connect(DB_PATH)
    load_sales().to_sql("sales", conn, if_exists="replace", index=False)
    load_products().to_sql("products", conn, if_exists="replace", index=False)
    load_customers().to_sql("customers", conn, if_exists="replace", index=False)
    load_stores().to_sql("stores", conn, if_exists="replace", index=False)
    load_exchange_rates().to_sql("exchange_rates", conn, if_exists="replace", index=False)
    conn.close()
    print(f"Database written to {DB_PATH}")


if __name__ == "__main__":
    main()
