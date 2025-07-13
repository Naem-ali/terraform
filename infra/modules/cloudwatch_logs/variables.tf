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

variable "alarm_thresholds" {
  description = "Map of alarm thresholds for different metrics"
  type = object({
    cpu_utilization    = number
    memory_utilization = number
    disk_utilization   = number
  })
  default = {
    cpu_utilization    = 80
    memory_utilization = 85
    disk_utilization   = 85
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}
