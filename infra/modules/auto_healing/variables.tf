variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "instance_ids" {
  description = "List of EC2 instance IDs to monitor"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "health_check_grace_period" {
  description = "Grace period in seconds for health checks"
  type        = number
  default     = 300
}

variable "unhealthy_threshold" {
  description = "Number of consecutive health check failures before recovery"
  type        = number
  default     = 3
}

variable "alert_email" {
  description = "Email address for recovery notifications"
  type        = string
}
