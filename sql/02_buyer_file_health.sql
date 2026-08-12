-- Buyer File Health: monthly acquisition cohorts and trailing rebuy rates

WITH cohort_stats AS (
    SELECT
        DATE_TRUNC('month', CAST(c.first_order_date AS DATE)) AS cohort_month,
        ch.channel_name AS acquisition_channel,
        COUNT(DISTINCT c.customer_id) AS customers,
        COUNT(DISTINCT CASE
            WHEN o.order_date > c.first_order_date AND o.is_size_exchange = 0
            THEN o.customer_id
        END) AS rebuyers
    FROM customers c
    JOIN marketing_channels ch
      ON ch.channel_id = c.acquisition_channel_id
    LEFT JOIN orders o ON o.customer_id = c.customer_id
    GROUP BY 1, 2
),
with_rate AS (
    SELECT
        cohort_month,
        acquisition_channel,
        customers,
        rebuyers,
        ROUND(100.0 * rebuyers / NULLIF(customers, 0), 1) AS rebuy_rate_pct
    FROM cohort_stats
),
with_benchmark AS (
    SELECT
        *,
        ROUND(
            AVG(rebuy_rate_pct) OVER (
                PARTITION BY acquisition_channel
                ORDER BY cohort_month
                ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
            ),
            1
        ) AS prior_3_cohort_avg_rebuy_pct
    FROM with_rate
)
SELECT
    cohort_month,
    acquisition_channel,
    customers,
    rebuy_rate_pct,
    prior_3_cohort_avg_rebuy_pct,
    CASE
        WHEN prior_3_cohort_avg_rebuy_pct IS NOT NULL
         AND rebuy_rate_pct < prior_3_cohort_avg_rebuy_pct - 5
        THEN 'needs_reactivation'
        ELSE 'ok'
    END AS health_flag
FROM with_benchmark
ORDER BY cohort_month DESC, acquisition_channel;
