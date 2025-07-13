locals {
  workspace = terraform.workspace
  
  # Merge workspace specific config with default values
  config = merge(
    local.workspace_config[local.workspace],
    {
      project     = local.project
      environment = local.environment
    }
  )
}
