resource "aws_lb" "main" {
  name               = "${var.project}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout              = var.idle_timeout

  access_logs {
    bucket  = var.enable_access_logs ? aws_s3_bucket.logs[0].id : null
    enabled = var.enable_access_logs
  }

  tags = {
    Name        = "${var.project}-${var.env}-alb"
    Environment = var.env
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.project}-${var.env}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    matcher             = "200-299"
    path               = var.health_check_path
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
  }

  tags = {
    Name        = "${var.project}-${var.env}-tg"
    Environment = var.env
  }
}

resource "aws_lb_target_group_attachment" "main" {
  count            = length(var.target_instances)
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = var.target_instances[count.index]
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != null ? "redirect" : "forward"
    
    dynamic "redirect" {
      for_each = var.certificate_arn != null ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.certificate_arn == null ? [1] : []
      content {
        target_group_arn = aws_lb_target_group.main.arn
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.env}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  dynamic "ingress" {
    for_each = var.certificate_arn != null ? [1] : []
    content {
      description = "HTTPS from allowed CIDRs"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.env}-alb-sg"
    Environment = var.env
  }
}

resource "aws_s3_bucket" "logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = "${var.project}-${var.env}-alb-logs"

  tags = {
    Name        = "${var.project}-${var.env}-alb-logs"
    Environment = var.env
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = var.logs_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs[0].arn}/*"
      }
    ]
  })
}

data "aws_elb_service_account" "main" {}

output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN of target group"
  value       = aws_lb_target_group.main.arn
}

output "security_group_id" {
  description = "ID of ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_zone_id" {
  description = "Zone ID of ALB"
  value       = aws_lb.main.zone_id
}
