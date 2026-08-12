# Marketing Analytics SQL Portfolio

Sample DTC marketing warehouse + SQL analyses that mirror real marketing measurement work:
channel cohort LTV, Buyer File Health, Meta buyer-file vs acquisition, Direct Mail holdout incrementality, brand vs non-brand search, and data quality checks.

Built for interview demos and to practice warehouse-style SQL (joins, CTEs, window functions, experiment readouts).

## Stack

- **DuckDB** (local analytical database; SQL is close to BigQuery/Snowflake style)
- CSV sample data you can also load into BigQuery / Snowflake later

## Quick start

```bash
cd marketing-sql-portfolio
py -3 -m pip install duckdb pandas
py -3 scripts/generate_sample_data.py
py -3 scripts/run_portfolio.py
```

This creates `marketing_analytics.duckdb` and prints each query result.

## Schema

| Table | Grain | Purpose |
|---|---|---|
| `customers` | one row per customer | acquisition channel + first order date |
| `orders` | one row per order | revenue, size-exchange flag, order channel |
| `mail_assignments` | customer x mail drop | mailed vs holdout for incrementality |
| `meta_spend` | day x campaign type | Meta buyer_file vs acquisition spend |

## Queries

| File | What it demonstrates |
|---|---|
| `01_channel_cohort_ltv.sql` | Multi-table join + group-by cohort/channel LTV |
| `02_buyer_file_health.sql` | Window functions to flag lagging rebuy cohorts |
| `03_meta_buyer_vs_acquisition.sql` | Separate Meta channels + acquisition purity audit |
| `04_dm_holdout_incrementality.sql` | Holdout vs mailed incremental lift |
| `05_brand_vs_nonbrand_search.sql` | Brand vs non-brand as distinct channels |
| `06_data_quality_checks.sql` | Anomaly / hygiene checks before trusting metrics |

## How to talk about this in interviews

- "I modeled acquisition to orders the same way we did for channel LTV, then wrote SQL for cohort rollups."
- "Buyer File Health uses window functions to compare a cohort's rebuy rate to recent peers."
- "Meta is split into buyer-file vs acquisition, then audited for existing-customer leakage."
- "Direct Mail incrementality is mailed vs holdout conversion and revenue in a 45-day window."

Be honest: this is a portfolio on sample data. Your Stio work was Excel/Power BI-first; this shows you can express the same logic in SQL.

## Optional next steps

1. Load the CSVs into BigQuery or Snowflake free tier and rerun the SQL with small dialect tweaks.
2. Connect Power BI / Looker to `marketing_analytics.duckdb` or the CSVs.
3. Add a `sessions` table with UTMs for multi-touch pathing practice.
