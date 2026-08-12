"""Load sample data into DuckDB and run all portfolio SQL files."""
from __future__ import annotations

import re
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql"
DB_PATH = ROOT / "marketing_analytics.duckdb"


def split_statements(sql: str) -> list[str]:
    # Strip line comments, then split on semicolons
    lines = []
    for line in sql.splitlines():
        if line.strip().startswith("--"):
            continue
        lines.append(line)
    cleaned = "\n".join(lines)
    parts = [p.strip() for p in cleaned.split(";")]
    return [p for p in parts if p]


def main() -> None:
    if not (ROOT / "data" / "customers.csv").exists():
        raise SystemExit("Missing data/. Run: py -3 scripts/generate_sample_data.py")

    if DB_PATH.exists():
        DB_PATH.unlink()

    con = duckdb.connect(str(DB_PATH))
    con.execute(f"SET file_search_path = '{ROOT.as_posix()}'")

    for path in sorted(SQL_DIR.glob("*.sql")):
        print("\n" + "=" * 72)
        print(path.name)
        print("=" * 72)
        statements = split_statements(path.read_text(encoding="utf-8"))
        for i, stmt in enumerate(statements, start=1):
            if len(statements) > 1:
                print(f"\n-- statement {i}")
            result = con.execute(stmt)
            try:
                df = result.fetchdf()
                if df is not None and len(df):
                    print(df.head(25).to_string(index=False))
                    if len(df) > 25:
                        print(f"... ({len(df)} rows total)")
                else:
                    print("(completed)")
            except Exception:
                print("(completed)")

    print(f"\nDatabase written to: {DB_PATH}")
    con.close()


if __name__ == "__main__":
    main()
