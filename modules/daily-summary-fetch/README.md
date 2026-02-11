# daily-summary-fetch module

This module creates a scheduled AWS Lambda function that fetches a URL once per schedule interval and writes the response body to an existing S3 bucket.

In this repository it is currently used to query the CUDL SOLR summary endpoint and write the response—which contains service usage statistics—into a file in S3, ready to be consumed by the dashboard workflow.

## What it creates

- A Python 3.12 Lambda function that:
  - Fetches `var.target_url`.
  - On HTTP 200, writes the response body to `s3://var.results_bucket_name/var.results_key_prefix/<YYYY-MM-DD>/service-stats.json` (date in UTC).
- A CloudWatch Logs log group for the Lambda.
- An IAM role and policy allowing:
  - Lambda execution and logging.
  - `s3:PutObject` into the specified results bucket.
- A CloudWatch Events / EventBridge rule and target that invoke the Lambda on a schedule.

## Inputs

- `name_prefix` (string, required)  
  Prefix for naming the Lambda, log group, and EventBridge rule.

- `target_url` (string, required)  
  URL to fetch (for example: `https://search.cudl.lib.cam.ac.uk/summary?keyword=*&format=sdmx`).

- `schedule_expression` (string, optional, default: `rate(1 day)`)  
  CloudWatch Events schedule expression (e.g. `rate(1 day)` or a `cron(...)` expression). This controls how often the Lambda runs.

- `results_bucket_name` (string, required)  
  Name of the existing S3 bucket in which to store fetched responses.

- `results_key_prefix` (string, optional, default: `cudl-summary/`)  
  Key prefix (folder) within the bucket under which summary files are written.

## Example usage

```hcl
module "daily_summary_fetch" {
  source = "../modules/daily-summary-fetch"

  name_prefix         = join("-", [local.environment, "cudl-summary"])
  target_url          = "https://search.cudl.lib.cam.ac.uk/summary?keyword=*&format=sdmx"
  schedule_expression = "rate(1 day)"
  results_bucket_name = lower("${var.environment}-${var.destination-bucket-name}")
  results_key_prefix  = "cudl-summary/"
}
```
