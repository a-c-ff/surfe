-- Performs cohort segmentation. Retention defined as paid subscription purchase following activation month. 
-- Reviews 12 months following created_utc in customer model

WITH customers AS(
SELECT 
      FORMAT_DATE('%Y-%m', created_utc) AS activation_month, 
      customer_id,
FROM `pure-rhino-455710-d9.surfe.customers`
GROUP BY 1,2),

invoices AS (
SELECT 
      FORMAT_DATE('%Y-%m', invoice_ts) AS invoice_month, 
      customer_id,
  FROM `pure-rhino-455710-d9.surfe.invoices`
  WHERE paid AND paid_at_utc IS NOT NULL 
  AND subscription IS NOT NULL
  AND total > 0
  GROUP BY 1,2
)

SELECT
  activation_month,
  COUNT(customers.customer_id) AS total_customers,
  -- count of unique customers who made a purchase in the month of / months following their activation month
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = customers.activation_month THEN customers.customer_id END) AS month_0,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 1 MONTH)) 
      THEN customers.customer_id END) AS month_1,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 2 MONTH)) 
      THEN customers.customer_id END) AS month_2,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 3 MONTH)) 
      THEN customers.customer_id END) AS month_3,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 4 MONTH)) 
      THEN customers.customer_id END) AS month_4,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 5 MONTH)) 
      THEN customers.customer_id END) AS month_5,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 6 MONTH)) 
      THEN customers.customer_id END) AS month_6,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 7 MONTH)) 
      THEN customers.customer_id END) AS month_7,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 8 MONTH)) 
      THEN customers.customer_id END) AS month_8,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 9 MONTH)) 
      THEN customers.customer_id END) AS month_9,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 10 MONTH)) 
      THEN customers.customer_id END) AS month_10,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 11 MONTH)) 
      THEN customers.customer_id END) AS month_11,
  COUNT(DISTINCT CASE WHEN invoices.invoice_month = FORMAT_DATE('%Y-%m', DATE_ADD(PARSE_DATE('%Y-%m', customers.activation_month), INTERVAL 12 MONTH)) 
      THEN customers.customer_id END) AS month_12,
FROM customers
LEFT JOIN invoices 
USING (customer_id)
GROUP BY 1
ORDER BY 1 ASC
