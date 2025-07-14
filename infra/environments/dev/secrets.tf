module "secrets" {
  source = "../../modules/secrets"

  project    = local.project
  env       = local.environment
  kms_key_id = module.kms.key_ids["secrets"]

  secrets_manager = {
    database = {
      description = "Database credentials"
      secret_key_value_pairs = {
        username = "admin"
        password = "secret-password"  # Use data source or external secret in production
        host     = "db.example.com"
        port     = "5432"
      }
      rotation_enabled    = true
      rotation_schedule  = "30"  # days
      rotation_lambda_arn = aws_lambda_function.rotate_db_password.arn
    }

    api_keys = {
      description = "Third-party API keys"
      secret_key_value_pairs = {
        stripe_secret_key = "sk_test_xxx"
        github_token     = "ghp_xxx"
      }
    }
  }

  parameter_store = {
    app_config = {
      description = "Application configuration"
      type        = "SecureString"
      value       = jsonencode({
        debug_mode = true
        api_url    = "https://api.dev.example.com"
        log_level  = "DEBUG"
      })
      tier = "Advanced"
    }

    feature_flags = {
      description = "Feature flags"
      type        = "StringList"
      value       = "feature1,feature2,feature3"
    }
  }

  depends_on = [
    module.kms
  ]
}
