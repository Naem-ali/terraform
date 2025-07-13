resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency

  datasources {
    s3_logs {
      enable = var.enable_s3_logs
    }
  }
}

resource "aws_s3_bucket" "findings" {
  bucket = "${var.project}-${var.env}-guardduty-findings"

  tags = {
    Name        = "${var.project}-${var.env}-guardduty-findings"
    Environment = var.env
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "findings" {
  bucket = aws_s3_bucket.findings.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    expiration {
      days = var.findings_retention_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "findings" {
  bucket = aws_s3_bucket.findings.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_guardduty_publishing_destination" "s3" {
  detector_id     = aws_guardduty_detector.main.id
  destination_arn = aws_s3_bucket.findings.arn
  kms_key_arn    = aws_kms_key.guardduty.arn

  depends_on = [
    aws_s3_bucket_policy.findings
  ]
}

resource "aws_kms_key" "guardduty" {
  description             = "KMS key for GuardDuty findings"
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
        Sid    = "Allow GuardDuty to use the key"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "findings" {
  bucket = aws_s3_bucket.findings.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow GuardDuty to use the bucket"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.findings.arn}/*"
      },
      {
        Sid    = "Allow GuardDuty to get bucket location"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:GetBucketLocation"
        Resource = aws_s3_bucket.findings.arn
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
