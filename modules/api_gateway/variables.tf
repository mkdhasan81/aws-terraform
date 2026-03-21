variable "name" {
  type        = string
  description = "Name prefix for the API Gateway (appended with '-api')"
}

variable "lambda_invoke_arn" {
  type        = string
  description = "Invoke ARN of the Lambda function to integrate with"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function (used for invoke permission)"
}

variable "stage_name" {
  type        = string
  description = "Deployment stage name (e.g. dev, prod)"
  default     = "dev"
}

variable "throttling_rate" {
  type        = number
  description = "Steady-state request rate limit (requests/sec)"
  default     = 100
}

variable "throttling_burst" {
  type        = number
  description = "Burst request limit"
  default     = 200
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 14
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all API Gateway resources"
  default     = {}
}
