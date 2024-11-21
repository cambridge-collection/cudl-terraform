resource "aws_cloudwatch_dashboard" "cudl" {
  dashboard_name = "${title(var.environment)}-CUDL"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/WAFV2", "AllowedRequests", "WebACL", module.base_architecture.waf_name, "Rule", "ALL"],
            ["AWS/WAFV2", "BlockedRequests", "WebACL", module.base_architecture.waf_name, "Rule", "ALL"]
          ],
          view    = "timeSeries"
          period  = 60
          stacked = false
          stat    = "Sum"
          region  = "us-east-1"
          title   = "WAF AllowedRequests/BlockedRequests"
          yAxis = {
            left = {
              label     = "Requests",
              min       = 0,
              showUnits = false
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "Region", "Global", "DistributionId", module.cudl_viewer.cloudfront_distribution_id, { "color" : "#2ca02c" }],
            ["AWS/CloudFront", "TotalErrorRate", "Region", "Global", "DistributionId", module.cudl_viewer.cloudfront_distribution_id, { "color" : "#ff7f0e" }],
            ["AWS/CloudFront", "BytesDownloaded", "Region", "Global", "DistributionId", module.cudl_viewer.cloudfront_distribution_id, { "yAxis" : "right", "color" : "#1f77b4" }]
          ],
          view    = "timeSeries"
          period  = 60
          stacked = false
          stat    = "Sum"
          region  = "us-east-1"
          title   = "Viewer CloudFront Distribution",
          yAxis = {
            right = {
              showUnits = false,
              min       = 0
              label     = "Bytes"
            },
            left = {
              label     = "Requests",
              min       = 0
              showUnits = false
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "TargetGroup", module.cudl_viewer.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "color" : "#ff7f0e" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "TargetGroup", module.cudl_viewer.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "color" : "#d62728" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", module.cudl_viewer.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "color" : "#2ca02c" }],
            ["AWS/ApplicationELB", "TargetConnectionErrorCount", "TargetGroup", module.cudl_viewer.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "color" : "#9467bd" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", module.cudl_viewer.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "yAxis" : "right", "stat" : "Average", "color" : "#1f77b4" }],
          ],
          view    = "timeSeries"
          period  = 60
          stacked = false
          stat    = "Sum"
          region  = "eu-west-1"
          title   = "Viewer Load Balancer"
          yAxis = {
            right = {
              showUnits = false,
              min       = 0
              label     = "Seconds"
            },
            left = {
              label     = "Requests",
              min       = 0
              showUnits = false
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "TargetGroup", module.solr.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "color" : "#ff7f0e" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "TargetGroup", module.solr.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "color" : "#d62728" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", module.solr.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "color" : "#2ca02c" }],
            ["AWS/ApplicationELB", "TargetConnectionErrorCount", "TargetGroup", module.solr.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "color" : "#9467bd" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", module.solr.alb_target_group_arn_suffix, "LoadBalancer", module.base_architecture.alb_arn_suffix, { "yAxis" : "right", "stat" : "Average", "color" : "#1f77b4" }],
          ],
          view    = "timeSeries"
          period  = 60
          stacked = false
          stat    = "Sum"
          region  = "eu-west-1"
          title   = "SOLR Load Balancer"
          yAxis = {
            right = {
              showUnits = false,
              min       = 0
              label     = "Seconds"
            },
            left = {
              label     = "Requests",
              min       = 0
              showUnits = false
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", module.cudl_viewer.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Average", "color" : "#e377c2", "label" : "CUDL-Viewer Average" }],
            ["AWS/ECS", "CPUUtilization", "ServiceName", module.cudl_services.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Average", "color" : "#ff7f0e", "label" : "CUDL-Services Average" }],
            ["AWS/ECS", "CPUUtilization", "ServiceName", module.solr.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Average", "color" : "#2ca02c", "label" : "SOLR Average" }],
            ["AWS/ECS", "CPUUtilization", "ServiceName", module.cudl_viewer.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Maximum", "color" : "#f7b6d2", "label" : "CUDL-Viewer Max" }],
            ["AWS/ECS", "CPUUtilization", "ServiceName", module.cudl_services.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Maximum", "color" : "#ffbb78", "label" : "CUDL-Services Max" }],
            ["AWS/ECS", "CPUUtilization", "ServiceName", module.solr.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Maximum", "color" : "#98df8a", "label" : "SOLR Max" }]
          ],
          view    = "timeSeries"
          period  = 60
          stacked = false
          region  = "eu-west-1"
          title   = "ECS Services CPU"
          yAxis = {
            left = {
              min = 0,
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", module.cudl_viewer.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Average", "color" : "#e377c2", "label" : "CUDL-Viewer Average" }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", module.cudl_services.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Average", "color" : "#ff7f0e", "label" : "CUDL-Services Average" }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", module.solr.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Average", "color" : "#2ca02c", "label" : "SOLR Average" }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", module.cudl_viewer.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Maximum", "color" : "#f7b6d2", "label" : "CUDL-Viewer Max" }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", module.cudl_services.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Maximum", "color" : "#ffbb78", "label" : "CUDL-Services Max" }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", module.solr.ecs_service_name, "ClusterName", module.base_architecture.ecs_cluster_name, { "stat" : "Maximum", "color" : "#98df8a", "label" : "SOLR Max" }]
          ],
          view    = "timeSeries"
          period  = 300
          stacked = false
          region  = "eu-west-1"
          title   = "ECS Services Memory"
          yAxis = {
            left = {
              min = 0,
              max = 100
            }
          }
        }
      }
    ]
  })
}
