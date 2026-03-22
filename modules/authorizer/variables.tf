variable "name_prefix" {
  type        = string
  description = "Prefix for all authorizer resource names"
  default     = ""
}

variable "authorizer_token" {
  type        = string
  description = "Secret bearer token the authorizer validates against. Store in tfvars or secrets manager — never hardcode."
  sensitive   = true
}

variable "role_arn" {
  type        = string
  description = "IAM role ARN for the authorizer Lambda"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all authorizer resources"
  default     = {}
}
