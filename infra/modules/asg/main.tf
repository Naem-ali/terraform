resource "aws_launch_template" "main" {
  name_prefix   = "${var.project}-${var.env}-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.asg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y aws-cloudwatch-agent
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:${aws_ssm_parameter.cw_agent.name}
              EOF
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.asg.name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project}-${var.env}-asg"
      Environment = var.env
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name                = "${var.project}-${var.env}-asg"
  target_group_arns   = var.target_group_arns
  health_check_type   = "ELB"
  vpc_zone_identifier = var.subnet_ids
  
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_grace_period = var.health_check_grace_period

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = {
      Name        = "${var.project}-${var.env}-asg"
      Environment = var.env
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

resource "aws_autoscaling_policy" "cpu_tracking" {
  name                   = "${var.project}-${var.env}-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type           = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target
  }
}

resource "aws_security_group" "asg" {
  name        = "${var.project}-${var.env}-asg-sg"
  description = "Security group for ASG instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${var.env}-asg-sg"
    Environment = var.env
  }
}

resource "aws_iam_role" "asg" {
  name = "${var.project}-${var.env}-asg-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "asg" {
  name = "${var.project}-${var.env}-asg-profile"
  role = aws_iam_role.asg.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.asg.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.asg.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_ssm_parameter" "cw_agent" {
  name  = "/${var.project}/${var.env}/cw-agent-config"
  type  = "String"
  value = jsonencode({
    metrics = {
      aggregation_dimensions = [["InstanceId"], ["AutoScalingGroupName"]]
      metrics_collected = {
        cpu    = {
          measurement = ["usage_active"]
          metrics_collection_interval = 60
        }
        memory = {
          measurement = ["used_percent"]
          metrics_collection_interval = 60
        }
        disk   = {
          measurement = ["used_percent"]
          metrics_collection_interval = 60
        }
      }
    }
  })
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

output "asg_name" {
  description = "Name of the ASG"
  value       = aws_autoscaling_group.main.name
}

output "asg_arn" {
  description = "ARN of the ASG"
  value       = aws_autoscaling_group.main.arn
}
