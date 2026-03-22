variable "name_prefix" {
  type        = string
  description = "Prefix for all authorizer resource names"
  default     = ""
}

variable "jwks_uri" {
  type        = string
  description = "Cognito JWKS endpoint for JWT signature verification"
}

variable "issuer" {
  type        = string
  description = "Cognito JWT issuer URL for iss claim validation"
}

variable "required_scope" {
  type        = string
  description = "OAuth2 scope required to access the API (e.g. 'https://api/read')"
  default     = ""
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
