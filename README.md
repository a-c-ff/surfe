# surfe
Analytics &amp; Insights Lead Technical Challenge


<b>1. Data Ingestion and Database Design</b>

<b>a. Write a data ingestion script</b> 

[Import CSV to Big Query](https://github.com/a-c-ff/surfe/blob/311e43f6cea1e3f0625f8e8d09018f8aec9ac8d5/gcs_to_big_query.py) 
About this script:

- Imports CSV from Google Drive to BigQuery, and loads the CSV into a DataFrame
- Includes reproducible column cleaning: converting all to lower case, trim leading and trailing spaces, and replaces spaces between words with underscores. This is important as columns such as "Created (UTC)" with spaces and special characters can cause issues when querying
- Creates two tables, accessible in BigQuery console: [`pure-rhino-455710-d9.surfe.invoices`](https://console.cloud.google.com/bigquery?ws=!1m5!1m4!4m3!1spure-rhino-455710-d9!2ssurfe!3sinvoices) and [`pure-rhino-455710-d9.surfe.customers`](https://console.cloud.google.com/bigquery?ws=!1m5!1m4!4m3!1spure-rhino-455710-d9!2ssurfe!3scustomers).

<b>b. Database design</b>: 

The primary key between two tables is: `id` in `customers` + `customers` in `invoices`. 

The below SQL was run in my Big Query console to normalise primary key name in both tables, and add clarity to column names:
	
      ALTER TABLE `pure-rhino-455710-d9.surfe.customers` RENAME COLUMN id TO customer_id;
      ALTER TABLE `pure-rhino-455710-d9.surfe.invoices` RENAME COLUMN id TO invoice_id;
      ALTER TABLE `pure-rhino-455710-d9.surfe.invoices` RENAME COLUMN customer TO customer_id;
      ALTER TABLE `pure-rhino-455710-d9.surfe.invoices` RENAME COLUMN date TO invoice_ts; -- frees up the column name 'date'
<i><b>Notes</b></i>
- Descriptions have been added to some columns in `customers` and `invoices`. Some assumptions were made. With more time and information, I would have clarified the source and definition of each column and added a clear and concise descriptions to all columns.
  ![image](https://github.com/user-attachments/assets/2033b966-eece-4c0c-9234-78846c50346a)

- Due date in `invoices` is a column that needs cleaning / additional tests. If I had time, I would have built the table in DBT and included accepted_value tests to handle *null* and odd values (e.g. due dates in 1970). Due dates weren't taken into account for the following steps, so this wasn't too much of a problem for this task.

![image](https://github.com/user-attachments/assets/249336b7-8df9-44ab-9d56-842f0de6896e)
<br>
<br>
<br>

<b>2. Monthly Recurring Revenue (MRR) Calculation:</b>

<b>a. Implement program to calculate the MRR of any customer at any given date</b>: [daily_MRR](https://github.com/a-c-ff/surfe/blob/surfe/daily_MRR.sql)

<i><b>Notes</b></i>
- Reporting on MRR at any given date requires gapless date grid. `invoices` is not a gapless date grid - a new row is created when an invoice is inserted. This means I needed to build a model with the right granulrity: one row, per customer, per day. This is what the `date_series` CTE in `daily_MRR` does. 


- `invoices` reports on multiple currencies (EUR, USD). Ideally, a staging model would transform monetary values to EUR so the team have standardised reporting on currencies further downstream. The `revenue` CTE performs this transformation, assuming a `0.91 EUR : 1 USD` conversion rate. There are options to update this to (a) a live integration (though fluctuations may impact forecasting ability), or (b) update to the conversion rate agreed by the Surfe leadership team.

  
- Only paid subscription invoices have been included in the ARPU and MRR calculations. While there is value to reporting on inactive customers (e.g. indicating the effectiveness of onboarding, invoice completion) or one-off payments (for total revenue), the focus on paid subscription allows us to focus on how much each customer is contributing on a recurring basis. It was assumed that all subscription invoices would have `subscription` populated, so the `revenue` CTE was filtered with `subscription IS NOT NULL`. 

- There were two columns to qualify an invoice as paid: `paid` and `paid_at_utc`. Although there were no identified cases where `paid = TRUE and paid_at_utc IS NULL` or  `paid = FALSE and paid_at_utc IS NOT NULL` , I included both columns just incase there are missing values introduced at a later date. I also checked if there were any instances `where paid and voided_at_utc is not null`. In the long term, I would introduce a DBT test that would check for instances where an invoice did not have corresponding columns updated so that we would be alerted to missing/incorrect values, rather than excluding these instances from the model. This missing value detection would be important for the models reliability.

- `invoices` has a lot of columns that I didn’t take into account for the MRR calculation. There is an opportunity to update the columns if they are useful further downstream. Depending on reporting needs, it might be beneficial to surface MRR by: currency (to split customers by country), applied coupons etc.
<br>
<br>
<b>b. Build a basic cohort segmentation of the MRR</b>: [cohort_segmentation.sql
](https://github.com/a-c-ff/surfe/blob/surfe/cohort_segmentation.sql)

<i>Limitations:</i>
- `created_utc` in `customers` was assumed to be the users activation date.
- I decided to not perform the % retention so that further downstream, we can report on both raw values and %. Generally, it is good practice to limit the number of transformations within the model to improve usability downstream.
- With more time, I would further optimise the Query. Some ideas:
  		(1) fewer date transformations to improve readability (e.g. dbt macros)
  		(2) move to Looker for better visualisation capabilities (e.g. colourful conditional formatting to make it easier to identify trends) 

<br>
<br>
<br>

<b>3. Data Analysis and Insights:</b>


<b>a. Analyze the calculated MRR data (from task 2) to identify trends and patterns.</b>

		Reporting period: 2024-12 to 2025-02
		
		- December 2025 performance:
		    - There was one high value active customer, producing €1,396,558 revenue
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

			*Monthly Active User defined as a unique customer_id having a paid subscription invoice in the given month
<br>
<br>

Implement program that will calculate:

a. <b>Month-over-month MRR growth</b>: [monthly_MRR.sql
](https://github.com/a-c-ff/surfe/blob/surfe/monthly_MRR.sql) reports on total active users, ARPU and MRR by month, and the month on month changes. 

Example output:
<img width="1032" alt="image" src="https://github.com/user-attachments/assets/d14092ee-dada-42db-9f90-07ca6874df65" />


b. <b>Identifying days with significant changes</b>: [daily_MRR](https://github.com/a-c-ff/surfe/blob/surfe/daily_MRR.sql)

`daily_MRR` creates gapless date grid using the MIN and MAX invoice date in invoices model. This supports MRR calculations over time, and data visualisation.

Example output:
  ![image](https://github.com/user-attachments/assets/66477920-b4cb-4485-ae5a-aa4c57cc26b0)

- This could be visualised as a time series graph in Looker. Example:
<img width="1067" alt="image" src="https://github.com/user-attachments/assets/a3ddb923-c786-4ef4-a48c-cf7d20c4a582" />
There could also be a moving average added. Reporting on this metric on a daily basis is more susceptible to volatility and false positives. 

- I then created a BQ table  called `daily_mrr` using the `CREATE OR REPLACE TABLE` function. I queried this in GoogleColab using Python following the steps outlined in [daily_mrr_significance](https://github.com/a-c-ff/surfe/blob/surfe/daily_mrr_significance.py). This script calculates statistically significant changes (95% confidence level) compared to the previous day.

- I originally set this script up a 95% confidence level + 1 day rolling mean window. I found that no fluctuations in daily MRR were reported as significant: the z-score was not very sensitive to changes. This is likely because there was only ~2 months paid invoice data avaialble, and there were no large day-to-day changes in MRR. More knowledge on the invoice frequency of Surfe could help contexualise the most suitable rolling mean window to use.   

- I decided to I update this the rolling mean window to 7 days. This improved the statistical power and variability detection. The script output identified two days with significant daily changes in MRR:
    
			date  		mrr_change  	z_score_change
			2025-02-01   	786827.00        1.964090
			2025-02-23 	 -680641.82       -1.972735


<b>c. Churn rate</b>: Unfortunately I ran out of time to complete this subtask.

<b>d. Biggest customers</b>: [top_100_customers.sql](https://github.com/a-c-ff/surfe/blob/surfe/top_100_customers.sql) returns the top 100 customers by total revenue to date.



<b> Summary </b>


 With more time and access to additional data, I would like to enhance this analysis:

- Segment user cohorts using more granualar subscription metadata e.g. plan type, business size (e.g. SME, enterprise)
- Cohort segmentation visualisation
- Contextualise patterns in retention by reflecting on CRM engagement strategy over time
- Explore additional metrics: retention rate, churn rate, total revenue (including one off payments), LTV, LTV : CAC, free to paid conversion rate (I noticed on site there's a free version), new customer growth
- Model column descriptions
- Query optimisation
- dbt for version control
