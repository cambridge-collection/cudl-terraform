// Former2 was used to create most of the bones for this but it does not seem to support exporting the WAYF so
// we need to create an entry for one.  This should include custom rule to restrict to 131.111.0.0./16 IPs.

#resource "aws_wafv2_web_acl" "example" {
#  name        = "managed-rule-example"
#  provider = "us-east-1"
#  description = "Example of a managed rule."
#  scope       = "REGIONAL"
#
#  default_action {
#    allow {}
#  }
#
#  rule {
#    name     = "rule-1"
#    priority = 1
#
#    override_action {
#      count {}
#    }
#
#    statement {
#      managed_rule_group_statement {
#        name        = "AWSManagedRulesCommonRuleSet"
#        vendor_name = "AWS"
#
#        rule_action_override {
#          action_to_use {
#            count {}
#          }
#
#          name = "SizeRestrictions_QUERYSTRING"
#        }
#
#        rule_action_override {
#          action_to_use {
#            count {}
#          }
#
#          name = "NoUserAgent_HEADER"
#        }
#
#        scope_down_statement {
#          geo_match_statement {
#            country_codes = ["US", "NL"]
#          }
#        }
#      }
#    }
#
#    token_domains = ["mywebsite.com", "myotherwebsite.com"]
#
#    visibility_config {
#      cloudwatch_metrics_enabled = false
#      metric_name                = "friendly-rule-metric-name"
#      sampled_requests_enabled   = false
#    }
#  }
#
#  tags = {
#    Tag1 = "Value1"
#    Tag2 = "Value2"
#  }
#
#  visibility_config {
#    cloudwatch_metrics_enabled = false
#    metric_name                = "friendly-metric-name"
#    sampled_requests_enabled   = false
#  }
#}