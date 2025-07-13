variable "vpc_id" {
  description = "VPC ID where firewall will be deployed"
  type        = string
}

variable "firewall_subnet_cidrs" {
  description = "CIDR blocks for firewall subnets"
  type        = list(string)
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "allowed_domains" {
  description = "List of allowed domains"
  type        = list(string)
  default     = ["*.amazonaws.com", "*.github.com"]
}

variable "blocked_domains" {
  description = "List of blocked domains"
  type        = list(string)
  default     = ["*.evil.com", "*.malware.com"]
}

variable "enable_logging" {
  description = "Enable logging to CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}
