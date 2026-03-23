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

variable "encrypted_client_secret" {
  type        = string
  description = "KMS-encrypted client secret ciphertext (base64-encoded)"
  default     = ""
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key used to decrypt the encrypted client secret"
  default     = ""
}

variable "m2m_token_url" {
  type        = string
  description = "M2M token endpoint URL for the client_credentials grant"
  default     = ""
}
