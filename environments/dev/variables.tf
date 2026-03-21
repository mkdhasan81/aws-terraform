variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "ap-southeast-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be valid CIDR notation."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs for subnet placement. Empty = auto-detect from region."
  default     = []
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
  default     = "dev-vpc-lambda"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda runtime identifier"
  default     = "python3.12"

  validation {
    condition     = contains(["python3.12", "python3.11", "nodejs20.x", "nodejs18.x", "java21"], var.lambda_runtime)
    error_message = "Unsupported Lambda runtime."
  }
}

variable "lambda_handler" {
  type        = string
  description = "Lambda handler in format file.method"
  default     = "index.handler"
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda memory in MB (128–10240)"
  default     = 128

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "lambda_memory_size must be between 128 and 10240 MB."
  }
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda timeout in seconds (1–900)"
  default     = 30

  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "lambda_timeout must be between 1 and 900 seconds."
  }
}

variable "lambda_deployment_package_path" {
  type        = string
  description = "Path to Lambda deployment zip. Empty = placeholder handler."
  default     = ""
}

variable "lambda_environment_variables" {
  type        = map(string)
  description = "Environment variables injected into the Lambda function"
  default     = {}
}

variable "api_throttling_rate" {
  type        = number
  description = "API Gateway steady-state request rate limit (requests/sec)"
  default     = 100
}

variable "api_throttling_burst" {
  type        = number
  description = "API Gateway burst request limit"
  default     = 200
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}
