-- Full channel x month spine (includes months with zero acquisitions)
-- Useful for cohort grids / dashboards that should not drop empty cells.

SELECT
    m.month_id,
    m.month_label,
    m.month_start,
    ch.channel_id,
    ch.channel_name,
    COUNT(c.customer_id) AS customers_acquired
FROM months m
CROSS JOIN marketing_channels ch
LEFT JOIN customers c
  ON c.acquisition_month_id = m.month_id
 AND c.acquisition_channel_id = ch.channel_id
GROUP BY
    m.month_id,
    m.month_label,
    m.month_start,
    ch.channel_id,
    ch.channel_name
ORDER BY m.month_start, ch.channel_id;
