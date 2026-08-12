-- Marketing channel spend by month (2023-2024)
-- Direct and Organic are unpaid channels (spend = 0).

SELECT
    month_label,
    channel_name,
    spend
FROM channel_monthly_spend
ORDER BY month_id, channel_id;


-- Paid channels only
SELECT
    month_label,
    channel_name,
    spend
FROM channel_monthly_spend
WHERE spend > 0
ORDER BY month_id, channel_id;
