import base64
import boto3
import gzip
import json
import logging
import os

log = logging.getLogger()
log.setLevel(logging.INFO)

S3_BUCKET = os.environ['S3_BUCKET']

s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    event['awslogs']['data'] is a base64 encoded string. The contents are gzip-
    encoded bytes that when unzipped contain JSON with log events from the 
    source CloudWatch Log Group
    """
    log.info(f"Received events for stream {context.log_stream_name} in Log Group {context.log_group_name}")
    s3_key = context.aws_request_id

    b64_data = event['awslogs']['data']
    data = base64.b64decode(b64_data)
    log_events = json.loads(gzip.decompress(data))
    log.info(log_events) # verify events content

    s3.put_object(
        Bucket=S3_BUCKET,
        Key=f"{s3_key}.json.gz",
        ContentType='application/gzip',
        Body=data
    )

if __name__ == '__main__':
    lambda_handler(None, None)
