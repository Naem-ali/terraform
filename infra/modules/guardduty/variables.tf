variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "findings_retention_days" {
  description = "Number of days to retain GuardDuty findings"
  type        = number
  default     = 90
}

variable "enable_s3_logs" {
  description = "Enable S3 Protection"
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = "Frequency of findings publication"
  type        = string
  default     = "FIFTEEN_MINUTES"
}
