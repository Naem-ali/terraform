variable "cidr_block" {
  description = "CIDR block for the VPC"
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

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for AWS services"
  type        = bool
  default     = true
}

variable "vpc_endpoint_services" {
  description = "List of VPC endpoint services to enable"
  type        = list(string)
  default     = ["s3", "dynamodb", "ssm", "ec2messages", "ssmmessages"]
}

variable "public_nacl_rules" {
  description = "List of rules for public subnet NACL"
  type = list(object({
    rule_number = number
    egress     = bool
    protocol   = string
    rule_action = string
    cidr_block = string
    from_port  = number
    to_port    = number
  }))
  default = [
    {
      rule_number = 100
      egress     = false
      protocol   = "tcp"
      rule_action = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 80
      to_port    = 80
    },
    {
      rule_number = 110
      egress     = false
      protocol   = "tcp"
      rule_action = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 443
      to_port    = 443
    },
    {
      rule_number = 120
      egress     = false
      protocol   = "tcp"
      rule_action = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535
    },
    {
      rule_number = 100
      egress     = true
      protocol   = "-1"
      rule_action = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
    }
  ]
}

variable "private_nacl_rules" {
  description = "List of rules for private subnet NACL"
  type = list(object({
    rule_number = number
    egress     = bool
    protocol   = string
    rule_action = string
    cidr_block = string
    from_port  = number
    to_port    = number
  }))
  default = [
    {
      rule_number = 100
      egress     = false
      protocol   = "-1"
      rule_action = "allow"
      cidr_block = "10.0.0.0/16"
      from_port  = 0
      to_port    = 0
    },
    {
      rule_number = 100
      egress     = true
      protocol   = "-1"
      rule_action = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
    }
  ]
}
