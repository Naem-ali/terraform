resource "aws_s3_bucket" "logs" {
  bucket = "${var.project}-${var.env}-${var.bucket_prefix}"
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "bucket_name" {
  value = aws_s3_bucket.logs.id
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "bucket_prefix" {
  type = string
}
