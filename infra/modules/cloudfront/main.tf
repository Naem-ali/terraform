resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project}-${var.env}-waf"
  description = "WAF for CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = var.waf_rules
    content {
      name     = rule.key
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        rule_group_reference_statement {
          dynamic "rule_action_override" {
            for_each = rule.value.rules
            content {
              name = rule_action_override.key
              action_to_use {
                dynamic "allow" {
                  for_each = rule.value.action == "allow" ? [1] : []
                  content {}
                }
                dynamic "block" {
                  for_each = rule.value.action == "block" ? [1] : []
                  content {}
                }
                dynamic "count" {
                  for_each = rule.value.action == "count" ? [1] : []
                  content {}
                }
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name               = rule.key
        sampled_requests_enabled  = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "${var.project}-${var.env}-waf-metrics"
    sampled_requests_enabled  = true
  }

  tags = merge(
    {
      Name        = "${var.project}-${var.env}-waf"
      Environment = var.env
      Project     = var.project
    },
    var.tags
  )
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.price_class
  aliases             = [var.domain_name]
  web_acl_id          = aws_wafv2_web_acl.main.id

  dynamic "origin" {
    for_each = var.origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.key
      origin_path = origin.value.origin_path

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [origin.value.custom_origin_config] : []
        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
        }
      }

      dynamic "s3_origin_config" {
        for_each = origin.value.s3_origin_config != null ? [origin.value.s3_origin_config] : []
        content {
          origin_access_identity = s3_origin_config.value.origin_access_identity
        }
      }
    }
  }

  default_cache_behavior {
    target_origin_id       = var.default_cache_behavior.target_origin_id
    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy
    allowed_methods        = var.default_cache_behavior.allowed_methods
    cached_methods         = var.default_cache_behavior.cached_methods
    cache_policy_id        = var.default_cache_behavior.cache_policy_id
    compress              = var.default_cache_behavior.compress
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(
    {
      Name        = "${var.project}-${var.env}-cloudfront"
      Environment = var.env
      Project     = var.project
    },
    var.tags
  )
}
