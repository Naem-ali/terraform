module "cloudtrail" {
  source = "../../modules/cloudtrail"

  project = local.project
  env     = local.environment
  
  enable_multi_region     = true
  enable_organization     = false
  enable_log_file_validation = true
  
  kms_key_id = module.kms.key_ids["cloudtrail"]
  
  include_data_events = {
    s3_buckets = {
      resource_type = "AWS::S3::Object"
      values        = ["arn:aws:s3:::"]
      read_write    = "All"
    }
    lambda_functions = {
      resource_type = "AWS::Lambda::Function"
      values        = ["arn:aws:lambda"]
      read_write    = "WriteOnly"
    }
  }
  
  retention_days = 365

  tags = {
    SecurityLevel = "High"
    Compliance   = "SOC2"
  }

  depends_on = [
    module.kms
  ]
}
