import boto3
import json
import logging
import os
import time

log = logging.getLogger()
log.setLevel(logging.INFO)

ECS_CLUSTER_NAME = os.environ['ECS_CLUSTER_NAME']
ECS_SERVICE_NAME = os.environ['ECS_SERVICE_NAME']

ecs = boto3.client('ecs')
ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    
    services = ecs.describe_services(
        cluster=ECS_CLUSTER_NAME,
        services=[ECS_SERVICE_NAME]
    ).get('services', [])
    
    desired_count = services[0]['desiredCount']
    pending_count = services[0]['pendingCount']
    running_count = services[0]['runningCount']

    status=f"""
    ECS Cluster: {ECS_CLUSTER_NAME}
    ECS Service: {ECS_SERVICE_NAME}
    Desired tasks: {desired_count}
    Pending tasks: {pending_count}
    Running tasks: {running_count}
    """
    log.info(status)
    
    if pending_count > 0:
        log.info(f"{pending_count} pending tasks found. Sleeping for 2 minutes")
        time.sleep(120)
        
    if pending_count + running_count < desired_count:
        log.info(f"Active tasks {pending_count + running_count} is less than desired count {desired_count}")
        log.info(f"Forcing deployment of {ECS_SERVICE_NAME} service now")

        task_arns = ecs.list_tasks(
            cluster=ECS_CLUSTER_NAME,
            serviceName=ECS_SERVICE_NAME,
            desiredStatus='STOPPED' # if running tasks is less than desired tasks, there must be a stopped task
        ).get('taskArns', [])

        if len(task_arns) < 1:
            msg = f"No stopped tasks found for {ECS_SERVICE_NAME} service"
            log.error(msg)
            return {'statusCode': 404, 'body': msg}
        tasks = ecs.describe_tasks(
            cluster=ECS_CLUSTER_NAME,
            tasks=task_arns
        )
        container_instance_arns = [
            task.get('containerInstanceArn') for task in tasks.get('tasks', [])
        ]
        container_instances = ecs.describe_container_instances(
            cluster=ECS_CLUSTER_NAME,
            containerInstances=container_instance_arns
        )
        instance_ids = [
            instance.get('ec2InstanceId') for instance in container_instances.get('containerInstances')
        ]
        log.info(f"Terminating container instances {instance_ids}")
        terminate_status = ec2.terminate_instances(InstanceIds=instance_ids)['ResponseMetadata']['HTTPStatusCode']
        return {
            'statusCode': terminate_status,
            'body': f"HTTP Status {terminate_status} terminating {instance_ids}"
        }
    
    default_msg = f"Desired count {desired_count} matches running count {running_count}"
    log.info(default_msg)
    return {
        'statusCode': 200,
        'body': default_msg
    }

if __name__ == '__main__':
    lambda_handler(None, None)
