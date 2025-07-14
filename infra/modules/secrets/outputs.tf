output "secrets_arns" {
  description = "Map of secret ARNs"
  value = {
    for k, v in aws_secretsmanager_secret.secrets : k => v.arn
  }
}

output "parameter_arns" {
  description = "Map of parameter ARNs"
  value = {
    for k, v in aws_ssm_parameter.parameters : k => v.arn
  }
}

output "secrets_names" {
  description = "Map of secret names"
  value = {
    for k, v in aws_secretsmanager_secret.secrets : k => v.name
  }
}

output "parameter_names" {
  description = "Map of parameter names"
  value = {
    for k, v in aws_ssm_parameter.parameters : k => v.name
  }
}
