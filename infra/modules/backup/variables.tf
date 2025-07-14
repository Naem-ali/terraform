variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "backup_plans" {
  description = "Map of backup plans to create"
  type = map(object({
    schedule             = string
    start_window        = optional(number, 60)
    completion_window   = optional(number, 120)
    cold_storage_after  = optional(number)
    delete_after        = optional(number)
    copy_actions        = optional(list(object({
      destination_vault_arn = string
      cold_storage_after   = optional(number)
      delete_after         = optional(number)
    })), [])
    tags                = optional(map(string), {})
  }))
}

variable "backup_selections" {
  description = "Map of backup selections to create"
  type = map(object({
    plan_name = string
    resources = list(string)
    tags      = optional(map(string), {})
  }))
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup"
  type        = bool
  default     = false
}

variable "cross_region_destination" {
  description = "Destination region for cross-region backup"
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "KMS key ID for backup encryption"
  type        = string
}
