provider "aws" {
  region = "eu-west-2"
}

terraform {
  backend "s3" {
    bucket         = "mfon21-kubadm-state-s3bucket"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
