module "cloudfront" {
  source = "../../modules/cloudfront"

  project     = local.project
  env        = local.environment
  domain_name = "app.${local.domain_name}"

  origins = {
    app_alb = {
      domain_name = module.alb.dns_name
      custom_origin_config = {
        origin_protocol_policy = "https-only"
      }
    }
    assets = {
      domain_name = module.s3_assets.bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = module.s3_assets.cloudfront_access_identity_path
      }
    }
  }

  default_cache_behavior = {
    target_origin_id = "app_alb"
    cache_policy_id  = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  waf_rules = {
    AWSManagedRulesCommonRuleSet = {
      priority = 1
      action   = "block"
      rules    = {
        SQLInjection = {
          name = "SQLInjection"
          positional_constraint = "CONTAINS"
          pattern = "SELECT.*FROM"
        }
        XSS = {
          name = "XSSMatch"
          positional_constraint = "CONTAINS"
          pattern = "<script>"
        }
      }
    }
    RateLimit = {
      priority = 2
      action   = "block"
      rules    = {
        RequestRate = {
          name = "RequestRateLimit"
          positional_constraint = "EXACTLY"
          pattern = "100"
        }
      }
    }
  }

  certificate_arn = module.acm.certificate_arn
  
  tags = {
    Service = "WebApp"
  }

  depends_on = [
    module.alb,
    module.s3_assets,
    module.acm
  ]
}
