variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "bucket_name" {
  type    = string
  default = "tfstate-dev-ap-southeast-1"
}

variable "dynamodb_table_name" {
  type    = string
  default = "tfstate-lock-dev"
}
