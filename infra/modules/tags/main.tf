locals {
  mandatory_tags = {
    Environment = var.env
    Project     = var.project
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
    Application = var.application_name
    BackupPolicy = var.backup_policy
  }

  resource_tags = merge(local.mandatory_tags, var.additional_tags)
}

variable "env" {}
variable "project" {}
variable "owner" {}
variable "cost_center" {}
variable "application_name" {}
variable "backup_policy" {
  default = "default"
}
variable "additional_tags" {
  default = {}
}

output "tags" {
  value = local.resource_tags
}
