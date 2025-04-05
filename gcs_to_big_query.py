# The following data ingestion cleans, uploads and loads CSV files from Google Drive -> Big Query. 
# It also includes reproducible column cleaning - converting all to lower case, trim leading and trailing, and replaces spaces between words with underscores.
# Before running this script, you need download the necessary CSV and upload to your Google Drive.

# Import libraries
import pandas as pd # To handle csv
import re           # To clean column names using regex 
import os           # To check directory
from google.colab import auth, drive
from google.cloud import bigquery, storage 

# Authenticate Google Account for Cloud SDK
auth.authenticate_user()

# Mount Google Drive
drive.mount('/content/drive')

# Set up Google Cloud credentials
PROJECT_ID = "pure-rhino-455710-d9"
DATASET_ID = "surfe"
# You can create a bucket using these steps in the console: https://cloud.google.com/storage/docs/creating-buckets#console 
BUCKET_NAME = "af-surfe"

# Initialize BigQuery and Storage clients
client = bigquery.Client(project=PROJECT_ID)
storage_client = storage.Client()

# Function to clean column names
def clean_column_name(col):
    col = col.lower().strip()  # Convert to lower case and trim leading and trailing spaces
    col = re.sub(r'\s*\(utc\)\s*', '_utc', col)  # Replace " (UTC)" with "utc"
    col = re.sub(r'\s+', '_', col)  # Replace spaces between words with underscores
    return col

# Process and upload CSV
def process_and_upload(csv_path, table_name):
    # Ensure the file exists in directory
    if not os.path.exists(csv_path):
        print(f"Error: File {csv_path} not found.")
        return

    # Load CSV into a DataFrame
    df = pd.read_csv(csv_path)

    # Apply clean_column_name function to clean column names
    df.columns = [clean_column_name(col) for col in df.columns]

    # Save cleaned CSV
    cleaned_csv_path = f"/content/cleaned_{table_name}.csv"
    df.to_csv(cleaned_csv_path, index=False)

    # Upload to GCS
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(f"{table_name}.csv")
    blob.upload_from_filename(cleaned_csv_path)
    print(f"Uploaded {cleaned_csv_path} to GCS.")

    # Load into BigQuery
    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1, #skip header
        autodetect=True,
    )

    uri = f"gs://{BUCKET_NAME}/{table_name}.csv"
    load_job = client.load_table_from_uri(uri, table_ref, job_config=job_config)
    load_job.result() 

    # Print confirmation message [if successful]
    print(f"Loaded data into BigQuery table {table_ref}.")

# Define Google Drive paths
invoices_csv_path = "/content/drive/My Drive/invoices.csv"
customers_csv_path = "/content/drive/My Drive/customers.csv"

# Process both files
process_and_upload(invoices_csv_path, "invoices")
process_and_upload(customers_csv_path, "customers")
