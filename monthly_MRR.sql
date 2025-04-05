-- 1. Generate gapless date grid using the MIN and MAX invoice date in invoices model. 
-- Ensures that even days with no invoices still appear. Supports daily MRR reporting.
WITH date_series AS (
SELECT date
FROM UNNEST(
        GENERATE_DATE_ARRAY(
            (SELECT MIN(DATE(invoice_ts)) FROM `pure-rhino-455710-d9.surfe.invoices`),   -- earliest invoice date
            (SELECT MAX(DATE(invoice_ts)) FROM `pure-rhino-455710-d9.surfe.invoices`),   -- latest invoice date
            INTERVAL 1 DAY                           
        )
    ) AS date
),
-- 2. Calculate revenue per user per day, and normalise invoice total reporting to EUR 2 decimal points
revenue AS (
SELECT 
    date_series.date,
    invoices.customer_id,
    invoices.total,
    invoices.currency,
    -- current conversion rate has been used. with time, this should be updated to a live or official internal conversion rate
    ROUND(
    CASE 
        WHEN LOWER(invoices.currency) = 'usd' THEN invoices.total * 0.91
        WHEN LOWER(invoices.currency) = 'eur' THEN invoices.total 
        ELSE NULL  -- if undefined currencies entered
        END
    ,2) AS revenue_eur
FROM date_series
    -- join customer to a gapless date in date_series
    LEFT JOIN `pure-rhino-455710-d9.surfe.customers` AS customers ON TRUE 
    -- join every invoice date to gapless date_series date 
    LEFT JOIN `pure-rhino-455710-d9.surfe.invoices` AS invoices ON DATE(invoices.invoice_ts) = date_series.date
    -- only include paid subscription invoices:
    WHERE paid AND paid_at_utc IS NOT NULL
    AND subscription IS NOT NULL
    GROUP BY 1,2,3,4
),

-- 3. Calculate APRU (total revenue / total active customers) and MRR (APRU * total active customers)
MRR AS (SELECT
    FORMAT_DATE('%Y-%m', revenue.date) AS month_year,
    COUNT(DISTINCT customer_id) AS total_customers,
    -- average revenue per user that month: (total revenue / total active customers)
    ROUND(SUM(revenue_eur) / COUNT(DISTINCT customer_id),2) as ARPU_EUR,
    -- monthly recurring revenue that month: (APRU * total active customers)
    ROUND(SUM(revenue_eur) / COUNT(DISTINCT customer_id) * COUNT(DISTINCT customer_id),2) as MRR_EUR
FROM revenue
GROUP BY 1
ORDER BY 1 ASC)

-- Perform MoM calculations
SELECT 
*,
-- output will be pct values rounded to 2dp - this makes it easier for BI tools to recognise as pct values.
  ROUND((MRR_EUR - LAG(MRR_EUR) OVER (ORDER BY month_year)) / LAG(MRR_EUR) OVER (ORDER BY month_year),2) AS MRR_mom_growth,
  ROUND((total_customers - LAG(total_customers) OVER (ORDER BY month_year)) / LAG(total_customers) OVER (ORDER BY month_year),2) AS total_customers_mom_growth,
  ROUND((ARPU_EUR - LAG(ARPU_EUR) OVER (ORDER BY month_year)) / LAG(ARPU_EUR) OVER (ORDER BY month_year),2) AS ARPU_mom_growth
FROM MRR
ORDER BY month_year ASC
