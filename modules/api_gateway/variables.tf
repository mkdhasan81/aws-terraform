variable "name" {
  type        = string
  description = "Name prefix for the API Gateway (appended with '-api')"
}

variable "lambda_invoke_arn" {
  type        = string
  description = "Invoke ARN of the backend Lambda function"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the backend Lambda function (used for invoke permission)"
}

variable "stage_name" {
  type        = string
  description = "Deployment stage name (e.g. dev, prod)"
  default     = "dev"
}

# ── Authorizer ────────────────────────────────────────────────────────────────

variable "authorizer_invoke_arn" {
  type        = string
  description = "Invoke ARN of the authorizer Lambda. Empty string disables the authorizer."
  default     = ""
}

variable "authorizer_function_name" {
  type        = string
  description = "Name of the authorizer Lambda function (used for invoke permission)"
  default     = ""
}

variable "authorizer_role_arn" {
  type        = string
  description = "IAM role ARN that API Gateway assumes to invoke the authorizer Lambda"
  default     = ""
}

variable "authorizer_ttl_seconds" {
  type        = number
  description = "Authorizer result cache TTL in seconds (0 = disabled)"
  default     = 300
}

# ── Throttling ────────────────────────────────────────────────────────────────

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
