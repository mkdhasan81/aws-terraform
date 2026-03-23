terraform {
  backend "s3" {
    bucket         = "tfstate-dev-ap-southeast-1"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "tfstate-lock-dev"
  }
}
