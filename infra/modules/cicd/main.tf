resource "aws_codepipeline" "main" {
  name     = "${var.project}-${var.env}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.id
    type     = "S3"
    encryption_key {
      id   = var.kms_key_id
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = var.repository_config.type == "GITHUB" ? "ThirdParty" : "AWS"
      provider         = var.repository_config.type
      version          = "1"
      output_artifacts = ["source"]

      configuration = var.repository_config.type == "GITHUB" ? {
        Owner                = var.repository_config.owner
        Repo                 = var.repository_config.name
        Branch              = var.repository_config.branch
        OAuthToken          = var.repository_config.oauth_token
        PollForSourceChanges = false
      } : {
        RepositoryName = var.repository_config.name
        BranchName     = var.repository_config.branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source"]
      version         = "1"
      
      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      version         = "1"
      run_order       = 1
      
      configuration = local.deploy_config[var.deploy_config.type]
    }
  }
}

resource "aws_codebuild_project" "main" {
  name          = "${var.project}-${var.env}-build"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.build_config.compute_type
    image                       = var.build_config.image
    type                        = var.build_config.type
    privileged_mode             = var.build_config.privileged_mode

    dynamic "environment_variable" {
      for_each = var.build_config.environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.build_config.buildspec
  }

  encryption_key = var.kms_key_id
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.project}-${var.env}-artifacts"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_key_id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }
}

# IAM roles and policies configuration...
# ...additional resources like CloudWatch Events, SNS notifications...
