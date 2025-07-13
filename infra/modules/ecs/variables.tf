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
  description = "List of subnet IDs for ECS tasks"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 80
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
}

variable "desired_count" {
  description = "Desired number of containers"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "CPU units for the container (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for the container in MB"
  type        = number
  default     = 512
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}
