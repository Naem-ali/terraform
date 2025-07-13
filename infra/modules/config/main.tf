resource "aws_s3_bucket" "config" {
  bucket = "${var.project}-${var.env}-config-logs"

  tags = {
    Name        = "${var.project}-${var.env}-config-logs"
    Environment = var.env
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = var.config_logs_retention_days
    }
  }
}

resource "aws_iam_role" "config_role" {
  name = "${var.project}-${var.env}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "config_policy" {
  name = "${var.project}-${var.env}-config-policy"
  role = aws_iam_role.config_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.config.arn,
          "${aws_s3_bucket.config.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "config:Put*",
          "ec2:Describe*",
          "config:Get*",
          "config:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project}-${var.env}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
    include_global_resources = true
  }
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
}

resource "aws_config_config_rule" "vpc_rules" {
  for_each = toset(var.config_rules)

  name = "${var.project}-${var.env}-${each.value}"

  source {
    owner             = "AWS"
    source_identifier = each.value
  }

  scope {
    compliance_resource_id = var.vpc_id
    compliance_resource_types = ["AWS::EC2::VPC"]
  }

  depends_on = [aws_config_configuration_recorder.main]
}
