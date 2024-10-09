data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "this" {
  cluster_name = var.ecs_cluster_name
}

data "aws_ecs_service" "this" {
  service_name = var.ecs_service_name
  cluster_arn  = data.aws_ecs_cluster.this.arn
}
