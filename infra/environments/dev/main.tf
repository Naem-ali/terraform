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

  enable_flow_logs         = true
  flow_logs_retention_days = 14  # Shorter retention for dev environment

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

  depends_on = [module.network_firewall]
}

module "network_firewall" {
  source = "../../modules/network_firewall"

  vpc_id               = module.vpc.vpc_id
  firewall_subnet_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
  env                  = "dev"
  project              = "demo"
  allowed_domains      = ["*.amazonaws.com", "*.github.com", "*.docker.com"]
  blocked_domains      = [
    "*.evil.com",
    "*.malware.com",
    "*.suspicious.com"
  ]
  enable_logging      = true
  log_retention_days = 14  # Shorter retention for dev environment
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

module "monitoring" {
  source = "../../modules/monitoring"

  project      = "demo"
  env         = "dev"
  vpc_id      = module.vpc.vpc_id
  alert_email = "alerts@example.com"
  instance_ids = module.ec2.instance_ids

  memory_threshold     = 85
  disk_threshold      = 90
  network_baseline    = 10000000  # 10MB/s for dev
  error_rate_threshold = 10       # More lenient for dev

  depends_on = [
    module.vpc,
    module.ec2,
    module.network_firewall
  ]
}

module "config" {
  source = "../../modules/config"

  project                   = "demo"
  env                      = "dev"
  vpc_id                   = module.vpc.vpc_id
  config_logs_retention_days = 30  # Shorter retention for dev environment
  config_rules             = [
    "vpc-sg-open-only-to-authorized-ports",
    "vpc-default-security-group-closed",
    "vpc-flow-logs-enabled",
    "vpc-network-acl-unused-check"
  ]

  depends_on = [
    module.vpc
  ]
}

module "guardduty" {
  source = "../../modules/guardduty"

  project                     = "demo"
  env                        = "dev"
  findings_retention_days     = 30  # Shorter retention for dev environment
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  enable_s3_logs             = true
}

module "xray" {
  source = "../../modules/xray"

  project       = "demo"
  env          = "dev"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
  sampling_rate = 10  # Higher sampling rate for dev environment

  depends_on = [
    module.vpc
  ]
}

module "alb" {
  source = "../../modules/alb"

  project              = "demo"
  env                 = "dev"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  target_instances    = module.ec2.instance_ids
  health_check_path   = "/health"
  allowed_cidrs       = ["0.0.0.0/0"]  # Restrict in production
  enable_access_logs  = true
  logs_retention_days = 14  # Shorter retention for dev environment
  enable_deletion_protection = false  # Easier cleanup in dev
  idle_timeout        = 60

  depends_on = [
    module.vpc,
    module.ec2
  ]
}

module "auto_healing" {
  source = "../../modules/auto_healing"

  project                   = "demo"
  env                      = "dev"
  instance_ids             = module.ec2.instance_ids
  target_group_arn         = module.alb.target_group_arn
  health_check_grace_period = 300
  unhealthy_threshold      = 3
  alert_email             = "alerts@example.com"

  depends_on = [
    module.ec2,
    module.alb
  ]
}
