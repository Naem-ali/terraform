variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
}

variable "create_public_zone" {
  description = "Whether to create a public hosted zone"
  type        = bool
  default     = true
}

variable "create_private_zone" {
  description = "Whether to create a private hosted zone"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for private hosted zone"
  type        = string
  default     = null
}

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    type    = string
    ttl     = number
    records = list(string)
    alias   = optional(object({
      name                   = string
      zone_id               = string
      evaluate_target_health = bool
    }))
  }))
  default = {}
}
