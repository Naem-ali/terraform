terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-yourname"
    key            = "test/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
