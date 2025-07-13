variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_http_cidrs" {
  description = "List of CIDR blocks allowed for HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
