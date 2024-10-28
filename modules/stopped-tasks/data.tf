data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "this" {
  cluster_name = var.ecs_cluster_name
}

data "aws_ecs_service" "this" {
  service_name = var.ecs_service_name
  cluster_arn  = data.aws_ecs_cluster.this.arn
}

data "aws_lb" "this" {
  name = var.alb_name
}

data "aws_lb_target_group" "this" {
  name = var.alb_target_group_name
}
