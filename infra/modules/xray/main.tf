resource "aws_iam_role" "xray" {
  name = "${var.project}-${var.env}-xray-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "xray.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.xray.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_xray_sampling_rule" "main" {
  rule_name      = "${var.project}-${var.env}-sampling"
  priority       = 1000
  version        = 1
  reservoir_size = 1
  fixed_rate     = var.sampling_rate / 100
  
  attributes = {
    Environment = var.env
  }

  service_name     = "*"
  service_type     = "*"
  host            = "*"
  http_method     = "*"
  url_path        = "*"
  resource_arn    = "*"
}

resource "aws_security_group" "xray" {
  name        = "${var.project}-${var.env}-xray-sg"
  description = "Security group for X-Ray daemon"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2000
    to_port     = 2000
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "X-Ray daemon port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.env}-xray-sg"
    Environment = var.env
  }
}

resource "aws_ecs_cluster" "xray" {
  name = "${var.project}-${var.env}-xray"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "xray" {
  family                   = "${var.project}-${var.env}-xray"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.xray.arn
  task_role_arn          = aws_iam_role.xray.arn

  container_definitions = jsonencode([
    {
      name  = "xray-daemon"
      image = "amazon/aws-xray-daemon"
      portMappings = [
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]
      environment = [
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.xray.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "xray"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "xray" {
  name            = "${var.project}-${var.env}-xray"
  cluster         = aws_ecs_cluster.xray.id
  task_definition = aws_ecs_task_definition.xray.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.xray.id]
    assign_public_ip = false
  }
}

resource "aws_cloudwatch_log_group" "xray" {
  name              = "/aws/xray/${var.project}-${var.env}"
  retention_in_days = 14

  tags = {
    Environment = var.env
    Project     = var.project
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_region" "current" {}
