module "vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.0.0.0/16"
  env        = "dev"
}

module "ec2" {
  source = "../../modules/ec2"
  env    = "dev"
}
