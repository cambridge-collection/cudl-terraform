variable "cluster_name_suffix" {
  default = "CUDLContentCluster"
}

resource "aws_ecs_cluster" "cudl-loader-ecs-cluster" {
  name = "${var.environment}-${var.cluster_name_suffix}"
  depends_on = [
    aws_vpc.cudl-content-loader-vpc,
    aws_ecs_capacity_provider.cudl-content-loader-capacity-provider
  ]
}

resource "aws_ecs_cluster_capacity_providers" "cudl-loader-ecs-cluster-capacity-provider" {
  cluster_name = aws_ecs_cluster.cudl-loader-ecs-cluster.name
  capacity_providers = [aws_ecs_capacity_provider.cudl-content-loader-capacity-provider.name]
}

resource "aws_ecs_service" "cudl-content-loader-ecs-service-definition" {
  name = "${var.environment}-cudlservice"
  cluster = aws_ecs_cluster.cudl-loader-ecs-cluster.arn
  desired_count = 1
  task_definition = aws_ecs_task_definition.cudl-content-loader-ecs-task-definition.arn
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100
  iam_role = "arn:aws:iam::563181399728:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS" // standard AWS role
  ordered_placement_strategy {
    type = "binpack"
    field = "memory"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.cudl-content-loader-lb-target-group.arn
    container_name = "dl-loader-ui"
    container_port = 8081
  }
  scheduling_strategy = "REPLICA"
  depends_on = [
    aws_ecs_task_definition.cudl-content-loader-ecs-task-definition
  ]
}

resource "aws_ecs_task_definition" "cudl-content-loader-ecs-task-definition" {
  tags = {
    name = "${var.environment}-cudl-content-loader-ecs-task-def"
  }
  container_definitions = templatefile("${path.module}/ecs_container_def.tftpl.json", {
    cudl_loader_secret_access_key = aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key.arn
    cudl_loader_secret_access_key_id = aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key-id.arn
    cudl_loader_env_file = "${aws_s3_bucket.cudl-env-file-bucket.arn}/${aws_s3_object.cudl-loader-env-file.key}"
    cudl_loader_image_loader_ui = "${aws_ecr_repository.cudl-content-loader-ui-ecr-repository.repository_url}:latest" //TODO not always latest
    cudl_loader_image_loader_db = "${aws_ecr_repository.cudl-content-loader-db-ecr-repository.repository_url}:latest" //TODO not always latest
    region = var.deployment-aws-region
    environment = var.environment
    cudl_loader_logs_name = "/ecs/CUDLContent"
    cudl_loader_container_port = 8081
    cudl_loader_host_port = 8081
  })

  family = "${var.environment}-CUDLContent"
  task_role_arn = aws_iam_role.cudl-content-loader-iam-task-role.arn
  execution_role_arn = aws_iam_role.cudl-content-loader-iam-task-role.arn
  network_mode = "bridge"

  volume {
    name = "${var.environment}-dl-loading-db-volume"
  }
  requires_compatibilities = [
    "EC2"
  ]
  cpu = "1536"
  memory = "1638"
  depends_on = [
    aws_ecs_cluster.cudl-loader-ecs-cluster,
    aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key,
    aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key-id,
    aws_iam_role.cudl-content-loader-iam-task-role
  ]
}