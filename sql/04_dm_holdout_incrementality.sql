-- Direct Mail holdout incrementality
-- Compares conversion and revenue for mailed vs holdout within each drop/audience.

WITH windowed AS (
    SELECT
        m.drop_id,
        m.drop_date,
        m.audience_type,
        m.customer_id,
        m.is_mailed,
        MAX(CASE
            WHEN o.order_id IS NOT NULL
             AND CAST(o.order_date AS DATE) BETWEEN CAST(m.drop_date AS DATE)
                 AND CAST(m.drop_date AS DATE) + 45
             AND o.is_size_exchange = 0
            THEN 1 ELSE 0
        END) AS converted_45d,
        COALESCE(SUM(CASE
            WHEN CAST(o.order_date AS DATE) BETWEEN CAST(m.drop_date AS DATE)
                 AND CAST(m.drop_date AS DATE) + 45
             AND o.is_size_exchange = 0
            THEN o.gross_revenue
        END), 0) AS revenue_45d
    FROM mail_assignments m
    LEFT JOIN orders o ON o.customer_id = m.customer_id
    GROUP BY 1, 2, 3, 4, 5
),
agg AS (
    SELECT
        drop_id,
        drop_date,
        audience_type,
        is_mailed,
        COUNT(*) AS customers,
        SUM(converted_45d) AS converters,
        ROUND(100.0 * AVG(converted_45d), 2) AS cvr_pct,
        ROUND(AVG(revenue_45d), 2) AS avg_revenue_45d,
        ROUND(SUM(revenue_45d), 2) AS total_revenue_45d
    FROM windowed
    GROUP BY 1, 2, 3, 4
)
SELECT
    a.drop_id,
    a.drop_date,
    a.audience_type,
    MAX(CASE WHEN a.is_mailed = 1 THEN a.cvr_pct END) AS mailed_cvr_pct,
    MAX(CASE WHEN a.is_mailed = 0 THEN a.cvr_pct END) AS holdout_cvr_pct,
    ROUND(
        MAX(CASE WHEN a.is_mailed = 1 THEN a.cvr_pct END)
        - MAX(CASE WHEN a.is_mailed = 0 THEN a.cvr_pct END),
        2
    ) AS incremental_cvr_pp,
    MAX(CASE WHEN a.is_mailed = 1 THEN a.avg_revenue_45d END) AS mailed_avg_rev,
    MAX(CASE WHEN a.is_mailed = 0 THEN a.avg_revenue_45d END) AS holdout_avg_rev,
    ROUND(
        MAX(CASE WHEN a.is_mailed = 1 THEN a.avg_revenue_45d END)
        - MAX(CASE WHEN a.is_mailed = 0 THEN a.avg_revenue_45d END),
        2
    ) AS incremental_avg_rev
FROM agg a
GROUP BY 1, 2, 3
ORDER BY drop_date, audience_type;
