variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "secrets_manager" {
  description = "Map of secrets to store in Secrets Manager"
  type = map(object({
    description             = string
    secret_string          = optional(string)
    secret_key_value_pairs = optional(map(string))
    recovery_window        = optional(number, 7)
    rotation_enabled       = optional(bool, false)
    rotation_schedule     = optional(string)
    rotation_lambda_arn   = optional(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "parameter_store" {
  description = "Map of parameters to store in Parameter Store"
  type = map(object({
    description = string
    type        = string  # String, StringList, or SecureString
    value       = string
    tier        = optional(string, "Standard")  # Standard, Advanced, or IntelligentTiering
    tags        = optional(map(string), {})
  }))
  default = {}
}
