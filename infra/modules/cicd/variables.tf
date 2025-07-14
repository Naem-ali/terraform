variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "repository_config" {
  description = "Source repository configuration"
  type = object({
    type          = string # "GITHUB" or "CODECOMMIT"
    name          = string
    branch        = string
    owner         = optional(string) # Required for GitHub
    oauth_token   = optional(string) # Required for GitHub
  })
}

variable "build_config" {
  description = "Build configuration"
  type = object({
    compute_type                = optional(string, "BUILD_GENERAL1_SMALL")
    image                      = optional(string, "aws/codebuild/amazonlinux2-x86_64-standard:3.0")
    type                       = optional(string, "LINUX_CONTAINER")
    privileged_mode            = optional(bool, false)
    buildspec                  = optional(string)
    environment_variables      = optional(map(string), {})
  })
  default = {}
}

variable "deploy_config" {
  description = "Deployment configuration"
  type = object({
    type         = string # "ECS", "LAMBDA", or "S3"
    service_name = string
    cluster_name = optional(string) # Required for ECS
    bucket_name  = optional(string) # Required for S3
    function_name = optional(string) # Required for Lambda
  })
}

variable "notification_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
