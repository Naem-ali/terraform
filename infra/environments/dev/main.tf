provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source = "../../modules/vpc"

  cidr_block           = "10.0.0.0/16"
  env                  = "dev"
  project              = "demo"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true  # Use single NAT Gateway for dev environment to save costs
  enable_vpc_endpoints = true
  vpc_endpoint_services = [
    "s3",
    "dynamodb",
    "ssm",
    "ec2messages",
    "ssmmessages"
  ]

  public_nacl_rules = concat(
    var.public_nacl_rules,
    [
      {
        rule_number = 130
        egress     = false
        protocol   = "tcp"
        rule_action = "allow"
        cidr_block = "10.0.0.0/8"
        from_port  = 22
        to_port    = 22
      }
    ]
  )
  
  private_nacl_rules = var.private_nacl_rules
}

module "security_groups" {
  source = "../../modules/security_groups"

  vpc_id           = module.vpc.vpc_id
  env              = "dev"
  project          = "demo"
  allowed_ssh_cidrs = ["10.0.0.0/8"]  # Restrict SSH access to internal network
}

module "ec2" {
  source = "../../modules/ec2"
  env    = "dev"
  vpc_security_group_ids = [module.security_groups.web_security_group_id]
}
