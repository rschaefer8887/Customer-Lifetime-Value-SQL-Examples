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
| `months` | one row per calendar month | cohort month dimension (`month_id`, `month_label`, etc.) |
| `marketing_channels` | one row per channel | Direct Mail, Paid Social, Email, Organic, Direct |
| `customers` | one row per customer | `acquisition_channel_id` + `acquisition_month_id` + first order date |
| `orders` | one row per order | `gross_revenue`, `cogs`, size-exchange flag, `order_channel_id` |
| `mail_assignments` | customer x mail drop | mailed vs holdout for incrementality |
| `meta_spend` | day x campaign type | Paid Social buyer_file vs acquisition spend |
| `channel_monthly_spend` | channel x month | Monthly spend by channel (Direct/Organic = 0) |

Acquisition channels in `marketing_channels`:
1. Direct Mail  
2. Paid Social  
3. Email  
4. Organic  
5. Direct  

Paid Social also carries `paid_social_subtype` on customers (`buyer_file` / `acquisition`) for Meta-style splits.

## Queries

| File | What it demonstrates |
|---|---|
| `01_channel_cohort_ltv.sql` | Cohorts by channel + month (joins `months`) |
| `02_buyer_file_health.sql` | Window functions to flag lagging rebuy cohorts |
| `03_meta_buyer_vs_acquisition.sql` | Paid Social subtype purity audit |
| `04_dm_holdout_incrementality.sql` | Holdout vs mailed incremental lift |
| `05_customers_by_acquisition_channel.sql` | Which channel acquired which customers |
| `06_data_quality_checks.sql` | Anomaly / hygiene checks including channel FK integrity |
| `07_channel_month_cohort_spine.sql` | Full channel x month grid (includes zeros) |
| `08_channel_margin.sql` | Gross margin by acquisition channel (`revenue - cogs`) |
| `09_channel_monthly_spend.sql` | Channel spend by month for 2023-2024 |
| `CLTV - Loss at Acquisition Query.sql` | Acquisitions by month/channel + margin, CAC, Loss at Acquisition |

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
