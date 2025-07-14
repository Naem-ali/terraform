terraform {
  backend "s3" {
    bucket         = "demo-dev-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "demo-dev-terraform-locks"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key"
    
    workspace_key_prefix = "workspaces"  # Enables workspace support
    
    # Additional security settings
    force_path_style = true
    skip_metadata_api_check = true
    
    # Enable versioning
    versioning = true
  }
}

# Backend infrastructure configuration
module "backend_config" {
  source = "../../modules/backend_config"

  project        = "demo"
  env           = "dev"
  region        = "us-west-2"
  replica_region = "us-east-1"  # For DynamoDB global tables
}
