# surfe
Analytics &amp; Insights Lead Technical Challenge


<b>1. Data Ingestion and Database Design</b>

a. [Write script to import CSV to Big Query: Data Ingestion script](https://github.com/a-c-ff/surfe/blob/311e43f6cea1e3f0625f8e8d09018f8aec9ac8d5/gcs_to_big_query.py)

This created two tables in BQ: [invoices](https://console.cloud.google.com/bigquery?ws=!1m5!1m4!4m3!1spure-rhino-455710-d9!2ssurfe!3sinvoices) and [customers](https://console.cloud.google.com/bigquery?ws=!1m5!1m4!4m3!1spure-rhino-455710-d9!2ssurfe!3scustomers).

b. Database design: Identified `id` in `customers` and `customers` in `invoices` as the primary key. 

Ran SQL in Big Query console to normalise primary key name in both tables, and add clarity to some column names:
	
      ALTER TABLE `pure-rhino-455710-d9.surfe.customers` RENAME COLUMN id TO customer_id
      ALTER TABLE `pure-rhino-455710-d9.surfe.invoices` RENAME COLUMN id TO invoice_id
      ALTER TABLE `pure-rhino-455710-d9.surfe.invoices` RENAME COLUMN customer TO customer_id
      ALTER TABLE `pure-rhino-455710-d9.surfe.invoices` RENAME COLUMN date TO invoice_ts
<i>Additional notes</i>
- Descriptions have been added to some columns in `customers` and `invoices`. Some assumptions were made. With more time and information, I would have clarified the source and definition of each column and added a clear and concise descriptions to all columns.
  ![image](https://github.com/user-attachments/assets/2033b966-eece-4c0c-9234-78846c50346a)

- Due date is a column that needs cleaning / additional tests. If I had time, I would have built the table in DBT and included accepted_value tests to handle *null* and odd values (e.g. due dates in 1970). Due dates weren't taken into account for the following steps, so this wasn't too much of a problem for this task.

![image](https://github.com/user-attachments/assets/249336b7-8df9-44ab-9d56-842f0de6896e)

  

<b>2. Monthly Recurring Revenue (MRR) Calculation:</b>

a. Implement program to calculate the MRR of any customer at any given date.

[SQL File
](https://github.com/a-c-ff/surfe/blob/surfe/monthly_MRR.sql)

<i>Limitations:</i>
- It was required to report on MRR on any given date. I noticed the invoices table is not a gapless date grid - a new row is created when an invoice is inserted. From this, I knew I needed to build a model that has one row, per customer, per day. That is the purpose of the `date_series` CTE.

  
- `invoices` reports on multiple currencies (EUR, USD). Ideally, a staging model would transform monetary values to EUR to support standardised reporting on currencies further downstream. These transformations have been applied in the query in the `revenue` CTE. For a more reliable model, this could be a live integration (though fluctuations may impact forecasting ability) or updated to the conversion rate agreed by the Surfe leadership team.

  
- Only paid subscription invoices have been included in the ARPU and MRR calculations. This was to focus on predictability, consistency and to support strategic insights about how much each customer is contributing on a recurring basis. It was assumed that all subscription invoices would have `subscription` populated so revenue was filtered with `subscription IS NOT NULL`.

- There were two columns to qualify an invoice as paid: `paid` and `paid_at_utc`. Although there were no identified cases where `paid = TRUE and paid_at_utc IS NULL` or  `paid = FALSE and paid_at_utc IS NOT NULL` , I included both columns just incase there are missing values. I also checked if there were any instances `where paid and voided_at_utc is not null`. In the long term, I would introduce a DBT test that would check for instances where an invoice did not have corresponding columns updated so that we would be alerted to missing/incorrect values, rather than excluding these instances from the model. 

- `invoices` has a lot of columns that I didn’t take into account for the MRR calculation. There is an opportunity to update the columns if they are needed further downstream. Depending on reporting needs, it might be beneficial to surface MRR by: currency, open/closed status, applied coupons, discounts, tax.

b. Build a basic cohort segmentation of the MRR.

[SQL File
](https://github.com/a-c-ff/surfe/blob/surfe/cohort_segmentation.sql)

<i>Limitations:</i>
- created_utc in `customers` was assumed to be the users activation date.
- query can be further optimised e.g. fewer date transformations / % retention insteead of raw customer count / moved to Python or Looker for better visualisation capabilities


<b>3. Data Analysis and Insights:</b>


a. Analyze the calculated MRR data (from task 2) to identify trends and patterns.

		Reporting period: 2024-12 to 2025-02
		
		- December 2025 performance:
		    - There was one high value customer, producing €1,396,558 revenue
		- January 2025 MoM performance:
		    - 🟢 A significant increase from 1 to 3,944 Monthly Active Users
		    - 🟢 A +2315% increase in MRR to €33,206,527
		    - 🟡 ARPU was €8,419. There was an expected MoM fall due to extreme customer growth outpacing revenue growth
		- February 2025 MoM performance:
		    - 🔴 -11% Monthly Active Users indicates a level of churn
		    - 🟢 +8% positive ARPU growth to €9,082
		    - 🟡 -4% decrease in MRR to €31,762,300
		    - Despite an increase in ARPU, MRR fell. Explaining the trend:
		        - Improved customer size/quality: Surfe is acquiring fewer, but higher-value, customers.
		        - Seasonality: a shorter month means fewer invoicing days
		        - Pricing strategy / fewer applied coupons: This might have reduced the incentive for new sign-ups or increased the likelihood of churn.

			*Monthly Active User defined as having a paid subscription invoice in the given month

Implement program that will calculate:

a. <b>Month-over-month MRR growth</b>
- SQL File: monthly_MRR 

- [BQ Link](https://console.cloud.google.com/bigquery?ws=!1m7!1m6!12m5!1m3!1spure-rhino-455710-d9!2sus-central1!3saf410dea-2367-4aa0-a789-ed1317ae3fa6!2e1)

- Example output: 
![image](https://github.com/user-attachments/assets/75c1f4c9-b8f8-4c4a-86fb-47a84acf83a5)


b. <b>Identifying days with significant changes</b>

- SQL File: [daily_MRR](https://github.com/a-c-ff/surfe/blob/surfe/daily_MRR.sql)

- Example output (this could be visualised as a time series graph in Looker with a moving average):
  ![image](https://github.com/user-attachments/assets/66477920-b4cb-4485-ae5a-aa4c57cc26b0)

  
- I then created a BQ table  called `daily_mrr` and pulled this into GoogleColab and created a Python Script, [daily_mrr_significance](https://github.com/a-c-ff/surfe/blob/surfe/daily_mrr_significance.py). This script uses the daily_mrr model to calculate statistically significant changes (95% confidence level) on a 7 day rolling window.

- Using a 95% confidence level + 1 day rollng mean window, there were no days with stat sig differences. I decided to I update this to 7 day window. There was not a lot of data, which makes the z score less sensitive to changes.

- This improved the detection ability and output identified two days with big daily changes in MRR:
    
			date  				mrr_change  		z_score_change
			2025-02-01   	786827.00        1.964090
			2025-02-23 	 -680641.82       -1.972735


c. Churn rate

- I unfortunately ran out of time to complete this subtask.

d. Biggest customers

- [File: Top 100 customers by revenue](https://github.com/a-c-ff/surfe/blob/surfe/top_100_customers.sql)
