variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "keys" {
  description = "Map of KMS keys to create"
  type = map(object({
    description             = string
    deletion_window_in_days = optional(number, 7)
    enable_key_rotation     = optional(bool, true)
    multi_region           = optional(bool, false)
    alias                  = string
    policy                 = optional(string)
    service_principals     = optional(list(string), [])
    tags                   = optional(map(string), {})
  }))
}

variable "key_administrators" {
  description = "List of ARNs of IAM users/roles that can administer the keys"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of ARNs of IAM users/roles that can use the keys"
  type        = list(string)
  default     = []
}
