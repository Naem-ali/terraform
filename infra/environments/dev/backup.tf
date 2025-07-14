module "backup" {
  source = "../../modules/backup"

  project = local.project
  env     = local.environment
  
  kms_key_id = module.kms.key_ids["backup"]
  
  enable_cross_region_backup  = true
  cross_region_destination   = "us-east-1"

  backup_plans = {
    database = {
      schedule            = "cron(0 5 ? * * *)"  # Daily at 5 AM
      cold_storage_after = 30
      delete_after      = 90
      copy_actions = [
        {
          destination_vault_arn = "arn:aws:backup:us-east-1:${data.aws_caller_identity.current.account_id}:backup-vault/${local.project}-${local.environment}-vault-replica"
          cold_storage_after   = 45
          delete_after        = 120
        }
      ]
      tags = {
        Type = "Database"
      }
    },
    
    filesystem = {
      schedule = "cron(0 1 ? * MON *)"  # Weekly on Monday at 1 AM
      cold_storage_after = 90
      delete_after      = 365
      tags = {
        Type = "FileSystem"
      }
    }
  }

  backup_selections = {
    rds_instances = {
      plan_name = "database"
      resources = [
        "arn:aws:rds:*:*:db:*"
      ]
      tags = {
        Backup = "true"
      }
    },
    
    efs_filesystems = {
      plan_name = "filesystem"
      resources = [
        "arn:aws:elasticfilesystem:*:*:file-system/*"
      ]
      tags = {
        Backup = "true"
      }
    },
    
    dynamodb_tables = {
      plan_name = "database"
      resources = [
        "arn:aws:dynamodb:*:*:table/*"
      ]
      tags = {
        Backup = "true"
      }
    },
    
    ebs_volumes = {
      plan_name = "filesystem"
      resources = [
        "arn:aws:ec2:*:*:volume/*"
      ]
      tags = {
        Backup = "true"
      }
    }
  }

  depends_on = [
    module.kms
  ]
}
