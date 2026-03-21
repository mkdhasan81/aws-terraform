variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "runtime" {
  type        = string
  description = "Lambda function runtime"
  default     = "python3.12"
}

variable "handler" {
  type        = string
  description = "Lambda function handler (file.method)"
  default     = "index.handler"
}

variable "memory_size" {
  type        = number
  description = "Lambda function memory in MB"
  default     = 128
}

variable "timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 30
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
  description = "VPC CIDR block used for Lambda security group outbound rules"
}

variable "lambda_role_arn" {
  type        = string
  description = "IAM role ARN for the Lambda function"
}

variable "deployment_package_path" {
  type        = string
  description = "Path to Lambda deployment zip. Empty string creates a placeholder."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all Lambda resources"
  default     = {}
}
