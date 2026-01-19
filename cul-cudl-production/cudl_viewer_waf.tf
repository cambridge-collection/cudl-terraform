resource "aws_wafv2_web_acl" "cudl_viewer" {
  name        = "${local.base_name_prefix}-cudl-viewer-waf-web-acl"
  provider    = aws.us-east-1
  description = "Managed by Terraform for ${local.environment} cudl-viewer"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  captcha_config {
    immunity_time_property {
      immunity_time = 6000
    }
  }

  challenge_config {
    immunity_time_property {
      immunity_time = 6000
    }
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
          name = "SizeRestrictions_QUERYSTRING"
          action_to_use {
            allow {}
          }
        }

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            allow {}
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
    name     = "${local.base_name_prefix}-cudl-viewer-waf-web-bot-control"
    priority = 6

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            enable_machine_learning = true
            inspection_level        = var.waf_bot_control_inspection_level
          }
        }

        dynamic "rule_action_override" {
          for_each = toset(var.waf_bot_control_rule_action_overrides)
          content {
            name = rule_action_override.key
            action_to_use {
              challenge {}
            }
          }
        }

        dynamic "scope_down_statement" {
          for_each = length(var.waf_bot_control_exclusions) > 0 ? [1] : []
          content {
            not_statement {
              statement {
                or_statement {

                  # Header-based exclusions
                  dynamic "statement" {
                    for_each = [for exclusion in var.waf_bot_control_exclusions : exclusion if exclusion.waf_bot_control_exclusion_header != null]
                    content {
                      byte_match_statement {
                        search_string = statement.value.waf_bot_control_exclusion_header_value
                        field_to_match {
                          single_header {
                            name = statement.value.waf_bot_control_exclusion_header
                          }
                        }
                        text_transformation {
                          priority = 0
                          type     = statement.value.waf_bot_control_exclusion_text_transform
                        }
                        positional_constraint = statement.value.waf_bot_control_exclusion_match_type
                      }
                    }
                  }

                  # URI-based exclusions
                  dynamic "statement" {
                    for_each = [for exclusion in var.waf_bot_control_exclusions : exclusion if exclusion.waf_bot_control_exclusion_uri != null]
                    content {
                      byte_match_statement {
                        search_string = statement.value.waf_bot_control_exclusion_uri
                        field_to_match {
                          uri_path {}
                        }
                        text_transformation {
                          priority = 0
                          type     = statement.value.waf_bot_control_exclusion_text_transform
                        }
                        positional_constraint = statement.value.waf_bot_control_exclusion_match_type
                      }
                    }
                  }

                } # End or_statement
              }   # End statement
            }     # End not_statement
          }       # End scope_down_statement
        }         # End dynamic scope_down_statement
      }           # End managed_rule_group_statement
    }             # End statement

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.base_name_prefix}-cudl-viewer-waf-web-bot-control"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${local.base_name_prefix}-Allow_Cambridge_VPN"
    priority = 3

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = "arn:aws:wafv2:us-east-1:438117829123:global/ipset/LibraryVPN/4fa85b1f-37af-4717-9bc7-ba824e793cb0"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.base_name_prefix}-Allow_Cambridge_VPN"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${local.base_name_prefix}-block-metasr-user-agent"
    priority = 4

    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string         = "MetaSr"
        positional_constraint = "CONTAINS"

        field_to_match {
          single_header {
            name = "user-agent"
          }
        }

        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.base_name_prefix}-block-metasr-user-agent"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${local.base_name_prefix}-cudl-viewer-waf-web-acl-rule-rate-limiting"
    priority = 5

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = 300
        aggregate_key_type    = "IP"
        evaluation_window_sec = 120
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.base_name_prefix}-cudl-viewer-waf-web-acl-rule-rate-limiting"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.base_name_prefix}-cudl-viewer-waf-web-acl-no-rule"
    sampled_requests_enabled   = true
  }
}
