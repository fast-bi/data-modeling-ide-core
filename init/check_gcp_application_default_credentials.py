from google.cloud import bigquery
import sys

def check_application_default_credentials():
    try:
        # Attempt to create a BigQuery client using application-default credentials
        bq_client = bigquery.Client()

        # Attempt to list datasets
        datasets = list(bq_client.list_datasets())

        if not datasets:
            # No datasets found; could be a permissions issue or no datasets available
            # We interpret this as a sign to potentially reauthenticate or check permissions
            print("🛑 Error:  No datasets accessible. Check permissions or reauthenticate if necessary.")
            print("👉 Run: gcloud auth application-default login")
            sys.exit(3)
        else:
            # Datasets are accessible; credentials are valid and have permissions
            print(f"Accessible datasets: {len(datasets)}")
    except Exception as e:
        # Handle unexpected errors quietly
        print(f"An error occurred: {e}")
        sys.exit(99)

# Run the check
check_application_default_credentials()
