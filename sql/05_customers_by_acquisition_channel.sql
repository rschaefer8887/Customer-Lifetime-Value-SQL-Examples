-- Which marketing channel acquired which customers?
-- Dimension join: marketing_channels -> customers

SELECT
    ch.channel_id,
    ch.channel_name,
    ch.channel_code,
    COUNT(c.customer_id) AS customers_acquired,
    MIN(CAST(c.first_order_date AS DATE)) AS earliest_acquisition,
    MAX(CAST(c.first_order_date AS DATE)) AS latest_acquisition
FROM marketing_channels ch
LEFT JOIN customers c
  ON c.acquisition_channel_id = ch.channel_id
GROUP BY 1, 2, 3
ORDER BY customers_acquired DESC;


-- Example customer-level detail (first 20 per channel shown via window)
WITH ranked AS (
    SELECT
        ch.channel_name AS acquisition_channel,
        c.customer_id,
        c.first_order_date,
        c.acquisition_utm_campaign,
        c.paid_social_subtype,
        ROW_NUMBER() OVER (
            PARTITION BY ch.channel_name
            ORDER BY c.first_order_date, c.customer_id
        ) AS rn
    FROM customers c
    JOIN marketing_channels ch
      ON ch.channel_id = c.acquisition_channel_id
)
SELECT
    acquisition_channel,
    customer_id,
    first_order_date,
    acquisition_utm_campaign,
    paid_social_subtype
FROM ranked
WHERE rn <= 5
ORDER BY acquisition_channel, first_order_date;
