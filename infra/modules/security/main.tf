module "waf" {
  source = "./waf"
  alb_arn = var.alb_arn
  environment = var.env
}

module "shield" {
  source = "./shield"
  enabled = var.env == "prod" ? true : false
}

module "secrets" {
  source = "./secrets"
  application_secrets = var.secrets
  kms_key_id = module.kms.key_id
}
