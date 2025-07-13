variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "sampling_rate" {
  description = "Percentage of requests to trace (0-100)"
  type        = number
  default     = 5
}

variable "vpc_id" {
  description = "VPC ID where X-Ray daemon will run"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where X-Ray daemon will run"
  type        = list(string)
}
