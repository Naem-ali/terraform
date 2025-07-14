resource "aws_backup_vault" "main" {
  name        = "${var.project}-${var.env}-vault"
  kms_key_arn = var.kms_key_id

  tags = {
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_backup_vault" "replica" {
  count = var.enable_cross_region_backup ? 1 : 0
  
  provider    = aws.replica
  name        = "${var.project}-${var.env}-vault-replica"
  kms_key_arn = var.kms_key_id

  tags = {
    Environment = var.env
    Project     = var.project
  }
}

resource "aws_backup_plan" "main" {
  for_each = var.backup_plans
  
  name = "${var.project}-${var.env}-${each.key}"

  rule {
    rule_name         = "backup_rule_${each.key}"
    target_vault_name = aws_backup_vault.main.name
    schedule          = each.value.schedule
    start_window      = each.value.start_window
    completion_window = each.value.completion_window

    dynamic "lifecycle" {
      for_each = each.value.cold_storage_after != null ? [1] : []
      content {
        cold_storage_after = each.value.cold_storage_after
        delete_after      = each.value.delete_after
      }
    }

    dynamic "copy_action" {
      for_each = each.value.copy_actions
      content {
        destination_vault_arn = copy_action.value.destination_vault_arn
        lifecycle {
          cold_storage_after = copy_action.value.cold_storage_after
          delete_after      = copy_action.value.delete_after
        }
      }
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = contains([for r in each.value.resources : split(":", r)[2]], "rds") ? [1] : []
    content {
      backup_options = {
        WindowsVSS = "enabled"
      }
      resource_type = "RDS"
    }
  }

  tags = merge(
    {
      Name        = "${var.project}-${var.env}-${each.key}"
      Environment = var.env
      Project     = var.project
    },
    each.value.tags
  )
}

resource "aws_backup_selection" "main" {
  for_each = var.backup_selections

  name         = "${var.project}-${var.env}-${each.key}"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.main[each.value.plan_name].id

  resources = each.value.resources

  dynamic "selection_tag" {
    for_each = each.value.tags
    content {
      type  = "STRINGEQUALS"
      key   = selection_tag.key
      value = selection_tag.value
    }
  }
}

resource "aws_iam_role" "backup" {
  name = "${var.project}-${var.env}-backup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup.name
}

resource "aws_iam_role_policy_attachment" "restore" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.backup.name
}
