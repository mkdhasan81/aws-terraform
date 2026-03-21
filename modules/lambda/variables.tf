variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime identifier"
  default     = "python3.12"
}

variable "handler" {
  type        = string
  description = "Lambda handler in format file.method"
  default     = "index.handler"
}

variable "memory_size" {
  type        = number
  description = "Lambda memory in MB"
  default     = 128
}

variable "timeout" {
  type        = number
  description = "Lambda timeout in seconds"
  default     = 30
}

variable "environment_variables" {
  type        = map(string)
  description = "Environment variables injected into the Lambda function"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the Lambda function will run"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the Lambda VPC config"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR block for Lambda security group egress rule"
}

variable "lambda_role_arn" {
  type        = string
  description = "IAM role ARN for the Lambda function"
}

variable "deployment_package_path" {
  type        = string
  description = "Path to Lambda deployment zip. Empty = placeholder handler."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all Lambda resources"
  default     = {}
}
