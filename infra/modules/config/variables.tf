variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "config_logs_retention_days" {
  description = "Number of days to retain AWS Config logs"
  type        = number
  default     = 365
}

variable "vpc_id" {
  description = "VPC ID to monitor"
  type        = string
}

variable "config_rules" {
  description = "List of AWS Config rules to enable"
  type        = list(string)
  default     = [
    "vpc-sg-open-only-to-authorized-ports",
    "vpc-default-security-group-closed",
    "vpc-flow-logs-enabled",
    "vpc-network-acl-unused-check",
    "vpc-vpn-2-tunnels-up"
  ]
}
