data "aws_region" "current" {}

data "aws_route53_zone" "main" {
  name         = "yourdomain.com"
  private_zone = false
}

data "aws_caller_identity" "current" {}
