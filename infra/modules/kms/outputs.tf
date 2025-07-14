output "key_arns" {
  description = "Map of key ARNs"
  value = {
    for k, v in aws_kms_key.keys : k => v.arn
  }
}

output "key_ids" {
  description = "Map of key IDs"
  value = {
    for k, v in aws_kms_key.keys : k => v.key_id
  }
}

output "aliases" {
  description = "Map of key aliases"
  value = {
    for k, v in aws_kms_alias.keys : k => v.name
  }
}
