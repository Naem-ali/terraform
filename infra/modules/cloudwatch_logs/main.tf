resource "aws_cloudwatch_log_group" "service_logs" {
  for_each = var.services

  name              = "/aws/${var.project}/${var.env}/${each.key}"
  retention_in_days = each.value.retention_days
  kms_key_id       = each.value.kms_encrypted ? aws_kms_key.logs[0].arn : null

  tags = {
    Environment = var.env
    Project     = var.project
    Service     = each.key
  }
}

resource "aws_cloudwatch_log_metric_filter" "service_metrics" {
  for_each = flatten([
    for service, config in var.services : [
      for filter in config.metric_filters : {
        key     = "${service}-${filter.name}"
        service = service
        filter  = filter
      }
    ]
  ])

  name           = each.value.filter.name
  pattern        = each.value.filter.pattern
  log_group_name = aws_cloudwatch_log_group.service_logs[each.value.service].name

  metric_transformation {
    name      = each.value.filter.metric.name
    namespace = each.value.filter.metric.namespace
    value     = each.value.filter.metric.value
  }
}

resource "aws_kms_key" "logs" {
  count = length([for s in var.services : s if s.kms_encrypted]) > 0 ? 1 : 0

  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_destination" "s3_export" {
  count = var.logs_bucket_name != null ? 1 : 0

  name       = "${var.project}-${var.env}-logs-destination"
  role_arn   = aws_iam_role.log_destination[0].arn
  target_arn = "arn:aws:s3:::${var.logs_bucket_name}"
}

resource "aws_iam_role" "log_destination" {
  count = var.logs_bucket_name != null ? 1 : 0
  name  = "${var.project}-${var.env}-log-destination"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

output "log_groups" {
  description = "Map of created log group names and ARNs"
  value = {
    for key, group in aws_cloudwatch_log_group.service_logs : key => {
      name = group.name
      arn  = group.arn
    }
  }
}
