# This script uses the daily_mrr model to calculate the rolling mean & standard deviation of daily changes. 
# It identifies days in a rolling window with statistically significant changes (where z score > 1.96, 95% confidence level)

from google.cloud import bigquery
import pandas as pd
import numpy as np
from scipy.stats import zscore

client = bigquery.Client(project="pure-rhino-455710-d9")

# Get daily_mrr table from BQ
query = """
SELECT date, MRR_EUR
FROM `pure-rhino-455710-d9.surfe.daily_mrr`
ORDER BY date ASC
"""

df = client.query(query).to_dataframe()

# Difference between daily MRR_EUR
df["mrr_change"] = df["MRR_EUR"].diff()

# Drop the first row as there is no point of comparison
df = df.dropna(subset=["mrr_change"])

# Calculate the rolling mean & standard deviation of the daily changes
# Guidance: 
      # window = Rolling window e.g. 1 day, 7 days, 30 days
      # min_periods = Number of observations. It is recommended to keep this the same as window selection, so that you only compute the z score with complete data.
df["rolling_mean_change"] = df["mrr_change"].rolling(window=7, min_periods=7).mean()
df["rolling_std_change"] = df["mrr_change"].rolling(window=7, min_periods=7).std()

# Z-score for daily changes: Calculates the mean MRR_EUR across all rows, then the mean standard deviation of MRR_EUR across all rows
df["z_score_change"] = (df["mrr_change"] - df["rolling_mean_change"]) / df["rolling_std_change"]

# Identify days with statistically significant changes (where z score > 1.96)
# 1.96 z-score = 95% confidence level
significant_changes = df[abs(df["z_score_change"]) > 1.96]

# Print statistically significant days and data
print(significant_changes[["date", "mrr_change", "z_score_change"]])
