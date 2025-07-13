resource "aws_route53_zone" "public" {
  count = var.create_public_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name        = "${var.project}-${var.env}-public"
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_route53_zone" "private" {
  count = var.create_private_zone ? 1 : 0
  name  = var.domain_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Name        = "${var.project}-${var.env}-private"
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_route53_record" "records" {
  for_each = var.records

  zone_id = var.create_public_zone ? aws_route53_zone.public[0].zone_id : aws_route53_zone.private[0].zone_id
  name    = each.key
  type    = each.value.type

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id               = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  dynamic "records" {
    for_each = each.value.alias == null ? [1] : []
    content {
      records = each.value.records
      ttl     = each.value.ttl
    }
  }
}

resource "aws_route53_health_check" "main" {
  for_each = {
    for k, v in var.records : k => v
    if lookup(v, "health_check", false)
  }

  fqdn              = each.key
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name        = "${var.project}-${var.env}-health-check-${each.key}"
    Environment = var.env
    Project     = var.project
  }
}

output "public_zone_id" {
  description = "ID of the public hosted zone"
  value       = var.create_public_zone ? aws_route53_zone.public[0].zone_id : null
}

output "private_zone_id" {
  description = "ID of the private hosted zone"
  value       = var.create_private_zone ? aws_route53_zone.private[0].zone_id : null
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = var.create_public_zone ? aws_route53_zone.public[0].name_servers : null
}
