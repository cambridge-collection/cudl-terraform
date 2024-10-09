import boto3
import json
import os
import time

ECS_CLUSTER_NAME = os.environ['ECS_CLUSTER_NAME']
ECS_SERVICE_NAME = os.environ['ECS_SERVICE_NAME']

ecs = boto3.client('ecs')

def lambda_handler(event, context):
    
    services = ecs.describe_services(
        cluster=ECS_CLUSTER_NAME,
        services=[ECS_SERVICE_NAME]
    ).get('services', [])
    
    desired_count = services[0]['desiredCount']
    pending_count = services[0]['pendingCount']
    running_count = services[0]['runningCount']
    
    if pending_count > 0:
        time.sleep(120)
        
    if pending_count + running_count < desired_count:
        response = ecs.update_service(
            cluster=ECS_CLUSTER_NAME,
            service=ECS_SERVICE_NAME,
            forceNewDeployment=True
        )

        return response
    
    return {
        'statusCode': 200,
        'body': f"Desired count {desired_count} matches running count {running_count}"
    }