variable "name_prefix" {
  type        = string
  description = "Prefix for IAM role names"
  default     = ""
}

variable "authorizer_lambda_arn" {
  type        = string
  description = "ARN of the authorizer Lambda function (used for invoke policy)"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all IAM resources"
  default     = {}
}
