variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "enable_multi_region" {
  description = "Enable multi-region trail"
  type        = bool
  default     = true
}

variable "enable_organization" {
  description = "Enable organization-wide logging"
  type        = bool
  default     = false
}

variable "enable_log_file_validation" {
  description = "Enable log file validation"
  type        = bool
  default     = true
}

variable "include_management_events" {
  description = "Include management events"
  type        = bool
  default     = true
}

variable "include_data_events" {
  description = "Configuration for data event logging"
  type = map(object({
    resource_type = string
    values        = list(string)
    read_write    = string
  }))
  default = {}
}

variable "retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 365
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
