module "cicd" {
  source = "../../modules/cicd"

  project = local.project
  env     = local.environment
  
  repository_config = {
    type    = "GITHUB"
    name    = "my-application"
    branch  = "main"
    owner   = "organization-name"
    oauth_token = data.aws_secretsmanager_secret_version.github_token.secret_string
  }

  build_config = {
    compute_type    = "BUILD_GENERAL1_SMALL"
    privileged_mode = true
    buildspec       = file("${path.module}/buildspec.yml")
    environment_variables = {
      ENVIRONMENT = local.environment
      REGISTRY   = aws_ecr_repository.app.repository_url
    }
  }

  deploy_config = {
    type         = "ECS"
    service_name = module.ecs.service_name
    cluster_name = module.ecs.cluster_name
  }

  notification_arn = module.sns.topic_arn
  kms_key_id      = module.kms.key_ids["cicd"]

  tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
  }

  depends_on = [
    module.kms,
    module.sns,
    module.ecs
  ]
}
