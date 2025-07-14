resource "aws_cloudtrail" "main" {
  name                          = "${var.project}-${var.env}-trail"
  s3_bucket_name               = aws_s3_bucket.trail.id
  include_global_service_events = true
  is_multi_region_trail        = var.enable_multi_region
  is_organization_trail        = var.enable_organization
  enable_log_file_validation   = var.enable_log_file_validation
  kms_key_id                   = var.kms_key_id

  dynamic "event_selector" {
    for_each = var.include_data_events
    content {
      read_write_type           = each.value.read_write
      include_management_events = var.include_management_events

      data_resource {
        type   = each.value.resource_type
        values = each.value.values
      }
    }
  }

  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudwatch.arn

  tags = merge(
    {
      Name        = "${var.project}-${var.env}-trail"
      Environment = var.env
      Project     = var.project
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_s3_bucket" "trail" {
  bucket        = "${var.project}-${var.env}-cloudtrail-logs"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    {
      Name        = "${var.project}-${var.env}-cloudtrail-logs"
      Environment = var.env
      Project     = var.project
    },
    var.tags
  )
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.trail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.trail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project}-${var.env}"
  retention_in_days = var.retention_days
  kms_key_id       = var.kms_key_id

  tags = merge(
    {
      Name        = "${var.project}-${var.env}-cloudtrail"
      Environment = var.env
      Project     = var.project
    },
    var.tags
  )
}

resource "aws_iam_role" "cloudwatch" {
  name = "${var.project}-${var.env}-cloudtrail-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "${var.project}-${var.env}-cloudtrail-cloudwatch"
  role = aws_iam_role.cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}
