variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the CloudFront distribution"
  type        = string
}

variable "origins" {
  description = "Origins configuration"
  type = map(object({
    domain_name = string
    origin_path = optional(string, "")
    custom_origin_config = optional(object({
      http_port              = optional(number, 80)
      https_port             = optional(number, 443)
      origin_protocol_policy = optional(string, "https-only")
      origin_ssl_protocols   = optional(list(string), ["TLSv1.2"])
    }))
    s3_origin_config = optional(object({
      origin_access_identity = optional(string)
    }))
  }))
}

variable "default_cache_behavior" {
  description = "Default cache behavior configuration"
  type = object({
    target_origin_id       = string
    viewer_protocol_policy = optional(string, "redirect-to-https")
    allowed_methods       = optional(list(string), ["GET", "HEAD", "OPTIONS"])
    cached_methods        = optional(list(string), ["GET", "HEAD"])
    cache_policy_id       = optional(string)
    compress             = optional(bool, true)
  })
}

variable "waf_rules" {
  description = "WAF rules configuration"
  type = map(object({
    priority = number
    action   = string  # "allow", "block", "count"
    rules    = map(object({
      name        = string
      positional_constraint = string
      pattern     = string
    }))
  }))
  default = {}
}

variable "certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
