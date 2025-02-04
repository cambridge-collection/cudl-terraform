resource "aws_wafv2_ip_set" "library_vpn" {
  name               = "sandbox-waf-ip-set"
  provider           = aws.us-east-1
  description        = "Managed by Terraform"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = ["131.111.0.0/16"]
}

resource "aws_wafv2_web_acl" "content_loader" {
  name        = "${module.content_loader.name_prefix}-waf-web-acl"
  provider    = aws.us-east-1
  description = "Managed by Terraform"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${module.content_loader.name_prefix}-waf-web-acl-no-rule"
    sampled_requests_enabled   = true
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

        dynamic "rule_action_override" {
          for_each = toset(var.content_loader_waf_common_ruleset_override_actions)
          content {
            name = rule_action_override.key
            action_to_use {
              allow {}
            }
          }
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

  rule {
    name     = "sandbox-waf-web-acl-rule-ip-set"
    priority = 4

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.library_vpn.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "sandbox-waf-web-acl-rule-ip-set"
      sampled_requests_enabled   = true
    }
  }
}
