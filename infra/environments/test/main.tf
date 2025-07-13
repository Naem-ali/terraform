module "vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.1.0.0/16"
  env        = "test"
}

module "ec2" {
  source = "../../modules/ec2"
  env    = "test"
}
