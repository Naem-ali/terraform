output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "vpc_endpoint_s3_id" {
  description = "ID of S3 VPC endpoint"
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

output "vpc_endpoint_dynamodb_id" {
  description = "ID of DynamoDB VPC endpoint"
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
}

output "vpc_interface_endpoints" {
  description = "Map of interface endpoint IDs"
  value       = try({ for k, v in aws_vpc_endpoint.interface_endpoints : k => v.id }, {})
}

output "flow_logs_bucket_arn" {
  description = "ARN of the flow logs S3 bucket"
  value       = try(aws_s3_bucket.flow_logs[0].arn, null)
}

output "flow_logs_bucket_name" {
  description = "Name of the flow logs S3 bucket"
  value       = try(aws_s3_bucket.flow_logs[0].id, null)
}
