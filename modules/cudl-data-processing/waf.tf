resource "aws_wafv2_web_acl" "this" {
  count = var.create_cloudfront_distribution ? 1 : 0

  name        = join("-", [var.environment, var.cloudfront_distribution_name, "waf-web-acl"])
  provider    = aws.us-east-1
  description = "Managed by Terraform for ${var.environment} ${var.cloudfront_distribution_name}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 0

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "NoUserAgent_HEADER"
        }
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = var.waf_use_rate_limiting ? [1] : []
    content {
      name     = join("-", [var.environment, var.cloudfront_distribution_name, "waf-web-acl-rule-rate-limiting"])
      priority = 3

      action {
        block {}
      }

      statement {
        rate_based_statement {
          limit                 = var.waf_rate_limit
          aggregate_key_type    = "IP"
          evaluation_window_sec = var.waf_rate_limiting_evaluation_window

          dynamic "scope_down_statement" {
            for_each = var.waf_rate_limiting_scope_down_uri != null ? [1] : []
            content {
              byte_match_statement {
                search_string         = var.waf_rate_limiting_scope_down_uri
                positional_constraint = var.waf_rate_limiting_scope_down_match_type
                field_to_match {
                  uri_path {}
                }
                text_transformation {
                  priority = 0
                  type     = "NORMALIZE_PATH"
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = join("-", [var.environment, var.cloudfront_distribution_name, "waf-web-acl-rule-rate-limiting"])
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = join("-", [var.environment, var.cloudfront_distribution_name, "waf-web-acl-no-rule"])
    sampled_requests_enabled   = true
  }
}
