variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "services" {
  description = "Map of services and their log configurations"
  type = map(object({
    retention_days = number
    export_to_s3  = bool
    kms_encrypted = bool
    metric_filters = list(object({
      name    = string
      pattern = string
      metric = object({
        name      = string
        namespace = string
        value     = string
      })
    }))
  }))
}

variable "logs_bucket_name" {
  description = "S3 bucket name for log exports"
  type        = string
  default     = null
}
