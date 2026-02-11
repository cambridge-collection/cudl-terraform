import json
import os
from datetime import datetime, timezone
from urllib import request, error

import boto3


def lambda_handler(event, context):
  target_url = os.environ.get("TARGET_URL")
  bucket = os.environ.get("S3_BUCKET")
  prefix = os.environ.get("S3_PREFIX", "")

  if not target_url or not bucket:
    raise RuntimeError("TARGET_URL and S3_BUCKET environment variables must be set")

  # Ensure prefix ends with a slash if provided
  if prefix and not prefix.endswith("/"):
    prefix = prefix + "/"

  # Use current UTC date for directory name, e.g. "2025-01-23/"
  today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
  key = f"{prefix}{today}/service-stats.json"

  try:
    with request.urlopen(target_url) as resp:
      status = resp.getcode()
      body = resp.read()
  except error.URLError as e:
    raise RuntimeError(f"Error fetching URL {target_url}: {e}") from e

  if status != 200:
    raise RuntimeError(f"Unexpected status code {status} when fetching {target_url}")

  s3 = boto3.client("s3")
  s3.put_object(
    Bucket=bucket,
    Key=key,
    Body=body,
    ContentType="application/json",
  )

  return {
    "statusCode": 200,
    "body": json.dumps(
      {
        "message": "Summary fetched and stored",
        "bucket": bucket,
        "key": key,
        "url": target_url,
      }
    ),
  }
