variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "public_nacl_rules" {
  description = "List of public NACL rules"
  type = list(object({
    rule_number = number
    egress     = bool
    protocol   = string
    rule_action = string
    cidr_block = string
    from_port  = number
    to_port    = number
  }))
  default = []
}

variable "private_nacl_rules" {
  description = "List of private NACL rules"
  type = list(object({
    rule_number = number
    egress     = bool
    protocol   = string
    rule_action = string
    cidr_block = string
    from_port  = number
    to_port    = number
  }))
  default = []
}
