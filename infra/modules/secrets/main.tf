resource "aws_secretsmanager_secret" "secrets" {
  for_each = var.secrets_manager

  name                    = "/${var.project}/${var.env}/${each.key}"
  description             = each.value.description
  kms_key_id             = var.kms_key_id
  recovery_window_in_days = each.value.recovery_window

  tags = merge(
    {
      Name        = "${var.project}-${var.env}-${each.key}"
      Environment = var.env
      Project     = var.project
      ManagedBy   = "terraform"
    },
    each.value.tags
  )
}

resource "aws_secretsmanager_secret_version" "secret_values" {
  for_each = var.secrets_manager

  secret_id = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = each.value.secret_key_value_pairs != null ? jsonencode(each.value.secret_key_value_pairs) : each.value.secret_string
}

resource "aws_secretsmanager_secret_rotation" "rotation" {
  for_each = {
    for k, v in var.secrets_manager : k => v
    if v.rotation_enabled
  }

  secret_id           = aws_secretsmanager_secret.secrets[each.key].id
  rotation_lambda_arn = each.value.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = try(tonumber(regex("\\d+", each.value.rotation_schedule)), 30)
  }
}

resource "aws_ssm_parameter" "parameters" {
  for_each = var.parameter_store

  name        = "/${var.project}/${var.env}/${each.key}"
  description = each.value.description
  type        = each.value.type
  value       = each.value.value
  tier        = each.value.tier
  key_id      = var.kms_key_id

  tags = merge(
    {
      Name        = "${var.project}-${var.env}-${each.key}"
      Environment = var.env
      Project     = var.project
      ManagedBy   = "terraform"
    },
    each.value.tags
  )
}
