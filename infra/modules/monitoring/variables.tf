variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to monitor"
  type        = string
}

variable "alert_email" {
  description = "Email address for alerting"
  type        = string
}

variable "instance_ids" {
  description = "List of EC2 instance IDs to monitor"
  type        = list(string)
}

variable "memory_threshold" {
  description = "Memory usage threshold percentage"
  type        = number
  default     = 80
}

variable "disk_threshold" {
  description = "Disk usage threshold percentage"
  type        = number
  default     = 85
}

variable "network_baseline" {
  description = "Network baseline in bytes"
  type        = number
  default     = 5000000  # 5MB/s
}

variable "error_rate_threshold" {
  description = "HTTP 5xx error rate threshold percentage"
  type        = number
  default     = 5
}
