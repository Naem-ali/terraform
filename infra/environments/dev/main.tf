provider "aws" {
  region = "us-west-2"
}

locals {
  project = "demo"
  environment = "dev"
}

module "vpc" {
  source = "../../modules/vpc"

  cidr_block           = "10.0.0.0/16"
  env                  = local.environment
  project              = local.project
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
  env                  = local.environment
  project              = local.project
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
  env              = local.environment
  project          = local.project
  allowed_ssh_cidrs = ["10.0.0.0/8"]  # Restrict SSH access to internal network
}

module "monitoring" {
  source = "../../modules/monitoring"

  project      = local.project
  env         = local.environment
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

  project                   = local.project
  env                      = local.environment
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

  project                     = local.project
  env                        = local.environment
  findings_retention_days     = 30  # Shorter retention for dev environment
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  enable_s3_logs             = true
}

module "xray" {
  source = "../../modules/xray"

  project       = local.project
  env          = local.environment
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
  sampling_rate = 10  # Higher sampling rate for dev environment

  depends_on = [
    module.vpc
  ]
}

module "acm" {
  source = "../../modules/acm"

  project  = local.project
  env     = local.environment
  domain_name = "dev.yourdomain.com"
  subject_alternative_names = ["*.dev.yourdomain.com"]
  
  tags = {
    ManagedBy = "terraform"
  }

  depends_on = [
    module.route53
  ]
}

module "alb" {
  source = "../../modules/alb"

  project              = local.project
  env                 = local.environment
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  target_instances    = module.ec2.instance_ids
  health_check_path   = "/health"
  allowed_cidrs       = ["0.0.0.0/0"]  # Restrict in production
  enable_access_logs  = true
  logs_retention_days = 14  # Shorter retention for dev environment
  enable_deletion_protection = false  # Easier cleanup in dev
  idle_timeout        = 60
  
  certificate_arn     = module.acm.certificate_arn

  depends_on = [
    module.vpc,
    module.acm
  ]
}

resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.yourdomain.com"
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

module "route53" {
  source = "../../modules/route53"

  project         = local.project
  env            = local.environment
  domain_name    = "yourdomain.com"
  
  create_public_zone  = true
  create_private_zone = true
  vpc_id             = module.vpc.vpc_id

  records = {
    "api.dev.yourdomain.com" = {
      type = "A"
      alias = {
        name                   = module.alb.alb_dns_name
        zone_id               = module.alb.alb_zone_id
        evaluate_target_health = true
      }
    }
    "www.dev.yourdomain.com" = {
      type = "A"
      alias = {
        name                   = module.alb.alb_dns_name
        zone_id               = module.alb.alb_zone_id
        evaluate_target_health = true
      }
    }
    "mail.dev.yourdomain.com" = {
      type    = "MX"
      ttl     = 300
      records = ["10 mail.yourdomain.com"]
    }
    "_dmarc.dev.yourdomain.com" = {
      type    = "TXT"
      ttl     = 300
      records = ["v=DMARC1; p=reject; rua=mailto:dmarc@yourdomain.com"]
    }
  }

  depends_on = [
    module.vpc,
    module.alb
  ]
}

module "ecs" {
  source = "../../modules/ecs"

  project               = local.project
  env                  = local.environment
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  target_group_arn     = module.alb.target_group_arn
  container_port       = 80
  container_image      = "nginx:latest"  # Replace with your container image
  desired_count        = 2
  cpu                  = 256
  memory               = 512
  alb_security_group_id = module.alb.security_group_id

  container_definitions = jsonencode([
    {
      name  = "${local.project}-${local.environment}-container"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.cloudwatch_logs.log_groups["api"].name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      # ...rest of container definition...
    }
  ])

  depends_on = [
    module.vpc,
    module.alb
  ]
}

module "auto_healing" {
  source = "../../modules/auto_healing"

  project                   = local.project
  env                      = local.environment
  instance_ids             = []  # ASG manages instances now
  target_group_arn         = module.alb.target_group_arn
  health_check_grace_period = 300
  unhealthy_threshold      = 3
  alert_email             = "alerts@example.com"

  depends_on = [
    module.ecs,
    module.alb
  ]
}

module "cloudwatch_logs" {
  source = "../../modules/cloudwatch_logs"

  project = local.project
  env     = local.environment
  
  alarm_thresholds = {
    cpu_utilization    = 70  # More lenient for dev
    memory_utilization = 75
    disk_utilization   = 80
  }

  alarm_actions = [
    module.sns.topic_arn,  # Assuming you have an SNS module
    "arn:aws:automate:${data.aws_region.current.name}:ec2:reboot"
  ]

  services = {
    api = {
      retention_days = 14
      export_to_s3  = true
      kms_encrypted = true
      metric_filters = [
        {
          name    = "errors"
          pattern = "[timestamp, requestid, level = ERROR, message]"
          metric = {
            name      = "ApiErrorCount"
            namespace = "CustomMetrics/Api"
            value     = "1"
          }
        }
      ]
    },
    web = {
      retention_days = 14
      export_to_s3  = true
      kms_encrypted = true
      metric_filters = [
        {
          name    = "5xx-errors"
          pattern = "[timestamp, requestid, status_code=5*]"
          metric = {
            name      = "5xxErrorCount"
            namespace = "CustomMetrics/Web"
            value     = "1"
          }
        }
      ]
    },
    auth = {
      retention_days = 30  # Keep auth logs longer
      export_to_s3  = true
      kms_encrypted = true
      metric_filters = [
        {
          name    = "failed-logins"
          pattern = "[timestamp, requestid, event = LOGIN_FAILED]"
          metric = {
            name      = "FailedLoginCount"
            namespace = "CustomMetrics/Auth"
            value     = "1"
          }
        }
      ]
    }
  }

  logs_bucket_name = module.s3_logs.bucket_name  # If you have an S3 bucket module

  depends_on = [
    module.vpc,
    module.sns
  ]
}
