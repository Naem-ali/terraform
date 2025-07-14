module "kms" {
  source = "../../modules/kms"

  project = local.project
  env     = local.environment

  key_administrators = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/admin-role"
  ]

  key_users = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/developer-role"
  ]

  keys = {
    s3 = {
      description = "KMS key for S3 encryption"
      alias      = "${local.project}-${local.environment}-s3"
      service_principals = ["s3"]
    }
    
    rds = {
      description = "KMS key for RDS encryption"
      alias      = "${local.project}-${local.environment}-rds"
      service_principals = ["rds"]
    }
    
    ebs = {
      description = "KMS key for EBS encryption"
      alias      = "${local.project}-${local.environment}-ebs"
      service_principals = ["ec2"]
    }
    
    secrets = {
      description = "KMS key for Secrets Manager"
      alias      = "${local.project}-${local.environment}-secrets"
      service_principals = ["secretsmanager"]
      deletion_window_in_days = 30  # Longer retention for sensitive keys
    }
    
    lambda = {
      description = "KMS key for Lambda encryption"
      alias      = "${local.project}-${local.environment}-lambda"
      service_principals = ["lambda"]
    }
    
    logs = {
      description = "KMS key for CloudWatch Logs"
      alias      = "${local.project}-${local.environment}-logs"
      service_principals = ["logs"]
    }
  }
}
