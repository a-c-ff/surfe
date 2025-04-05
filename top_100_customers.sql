WITH revenue AS (
SELECT 
    DISTINCT invoices.customer_id,
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
FROM `pure-rhino-455710-d9.surfe.customers` AS customers 
    LEFT JOIN `pure-rhino-455710-d9.surfe.invoices` AS invoices 
    ON customers.customer_id = invoices.customer_id
    WHERE paid AND paid_at_utc IS NOT NULL
    AND subscription IS NOT NULL
    GROUP BY 1,2,3,4
),

  -- rank customers by total revenue, all time
ranked_revenue AS (
SELECT
    DISTINCT customer_id,
    ROUND(SUM(revenue_eur),2) AS revenue_mrr,
    ROW_NUMBER() OVER (ORDER BY ROUND(SUM(revenue_eur),2) DESC) AS revenue_rank
FROM revenue
    GROUP BY customer_id
)

-- provide top 100 customers
SELECT
    DISTINCT customer_id,
    revenue_mrr
FROM ranked_revenue
WHERE revenue_rank <= 100
ORDER BY 2 DESC;
