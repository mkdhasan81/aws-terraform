variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be a valid CIDR notation."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones. Empty list auto-detects from the region."
  default     = []
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "dev-cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for EKS"
  default     = "1.29"
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types for EKS worker nodes"
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 3
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2

  validation {
    condition     = var.node_desired_size >= 1
    error_message = "node_desired_size must be at least 1."
  }
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
  default     = "dev-vpc-lambda"
}

variable "lambda_runtime" {
  type        = string
  description = "Lambda function runtime"
  default     = "python3.12"
}

variable "lambda_handler" {
  type        = string
  description = "Lambda function handler"
  default     = "index.handler"
}

variable "lambda_memory_size" {
  type        = number
  description = "Lambda function memory in MB"
  default     = 128
}

variable "lambda_timeout" {
  type        = number
  description = "Lambda function timeout in seconds"
  default     = 30
}

variable "lambda_deployment_package_path" {
  type        = string
  description = "Path to Lambda deployment zip. Empty string creates a placeholder."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}
