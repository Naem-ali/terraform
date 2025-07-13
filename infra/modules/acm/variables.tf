variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Main domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names for the certificate"
  type        = list(string)
  default     = []
}

variable "validation_method" {
  description = "Domain validation method"
  type        = string
  default     = "DNS"
}

variable "tags" {
  description = "Additional tags for the certificate"
  type        = map(string)
  default     = {}
}
