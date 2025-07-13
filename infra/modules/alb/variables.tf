variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ALB"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of SSL certificate"
  type        = string
  default     = null
}

variable "target_instances" {
  description = "List of target instance IDs"
  type        = list(string)
  default     = []
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "allowed_cidrs" {
  description = "List of allowed CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = true
}

variable "logs_retention_days" {
  description = "Number of days to retain ALB logs"
  type        = number
  default     = 30
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "ALB idle timeout"
  type        = number
  default     = 60
}
