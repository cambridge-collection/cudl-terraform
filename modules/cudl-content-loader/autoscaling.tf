resource "aws_autoscaling_group" "cudl-loader-cudl-auto-scaling-group" {
  name = "${var.environment}-cudlautoscalinggroup"
  launch_template {
    id = aws_launch_template.cudl-loader-ec2-launch-template.id
    version = "$Latest"
  }
  min_size = 1
  max_size = 1
  desired_capacity = 1
  default_cooldown = 300

  health_check_type = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier = [
    aws_subnet.cudl-content-loader-ec2-subnet-public1.id
  ]
  termination_policies = [
    "Default"
  ]
  service_linked_role_arn = "arn:aws:iam::563181399728:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling" // AWS standard role
  metrics_granularity = "1Minute"
  enabled_metrics = [
    "GroupTotalInstances",
    "WarmPoolWarmedCapacity",
    "GroupInServiceCapacity",
    "GroupAndWarmPoolDesiredCapacity",
    "GroupMaxSize",
    "WarmPoolTotalCapacity",
    "GroupAndWarmPoolTotalCapacity",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "WarmPoolMinSize",
    "WarmPoolDesiredCapacity",
    "GroupMinSize",
    "WarmPoolPendingCapacity",
    "WarmPoolTerminatingCapacity",
    "GroupPendingCapacity",
    "GroupInServiceInstances",
    "GroupTotalCapacity",
    "GroupDesiredCapacity",
    "GroupTerminatingCapacity",
    "GroupPendingInstances"
  ]
  tag {
    key = "AmazonECSManaged"
    value = true
    propagate_at_launch = true
  }
  depends_on = [
    aws_vpc.cudl-content-loader-vpc,
    aws_subnet.cudl-content-loader-ec2-subnet-public1,
    aws_launch_template.cudl-loader-ec2-launch-template
  ]
}

resource "aws_autoscaling_policy" "cudl-loader-auto-scaling-group-policy" {
  autoscaling_group_name = "${var.environment}-cudlautoscalinggroup"
  name = "${var.environment}-cudl-auto-scaling-group-policy"
  policy_type = "TargetTrackingScaling"
  estimated_instance_warmup = 300
  target_tracking_configuration {
    customized_metric_specification {

      metric_dimension {
        name = "CapacityProviderName"
        value = aws_ecs_capacity_provider.cudl-content-loader-capacity-provider.name
      }
      metric_dimension {
        name = "ClusterName"
        value = aws_ecs_cluster.cudl-loader-ecs-cluster.name
      }

      metric_name = "CapacityProviderReservation"
      namespace = "AWS/ECS/ManagedScaling"
      statistic = "Average"
    }
    disable_scale_in = false
    target_value = 100
  }

  depends_on = [
    aws_vpc.cudl-content-loader-vpc,
    aws_ecs_cluster.cudl-loader-ecs-cluster,
    aws_subnet.cudl-content-loader-ec2-subnet-public1,
    aws_launch_template.cudl-loader-ec2-launch-template,
    aws_autoscaling_group.cudl-loader-cudl-auto-scaling-group
  ]
}

resource "aws_ecs_capacity_provider" "cudl-content-loader-capacity-provider" {
  name = "${var.environment}-cudlcapacityprovider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.cudl-loader-cudl-auto-scaling-group.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 1
    }
  }
}