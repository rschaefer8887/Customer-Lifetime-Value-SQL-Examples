-- Customers acquired by month and channel:
-- margin per customer, CAC, and Loss at Acquisition per Customer

WITH cohort AS (
    SELECT
        m.month_id,
        m.month_label,
        ch.channel_id,
        ch.channel_name,
        COUNT(DISTINCT c.customer_id) AS customers_acquired,
        ROUND(
            COALESCE(
                SUM(
                    CASE
                        WHEN o.is_size_exchange = 0 THEN o.gross_revenue - o.cogs
                        ELSE 0
                    END
                ),
                0
            ),
            2
        ) AS margin_dollars
    FROM months m
    CROSS JOIN marketing_channels ch
    LEFT JOIN customers c
      ON c.acquisition_month_id = m.month_id
     AND c.acquisition_channel_id = ch.channel_id
    LEFT JOIN orders o
      ON o.customer_id = c.customer_id
    GROUP BY m.month_id, m.month_label, ch.channel_id, ch.channel_name
)
SELECT
    cohort.month_label,
    cohort.channel_name,
    cohort.customers_acquired,
    ROUND(
        cohort.margin_dollars / NULLIF(cohort.customers_acquired, 0),
        2
    ) AS margin_per_customer,
    ROUND(COALESCE(s.spend, 0), 2) AS marketing_spend,
    ROUND(
        COALESCE(s.spend, 0) / NULLIF(cohort.customers_acquired, 0),
        2
    ) AS cac,
    ROUND(
        (cohort.margin_dollars - COALESCE(s.spend, 0))
        / NULLIF(cohort.customers_acquired, 0),
        2
    ) AS "Loss at Acquisition per Customer"
FROM cohort
LEFT JOIN channel_monthly_spend s
  ON s.month_id = cohort.month_id
 AND s.channel_id = cohort.channel_id
ORDER BY cohort.month_id, cohort.channel_id;
