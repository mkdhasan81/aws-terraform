variable "name_prefix" {
  type        = string
  description = "Prefix for the KMS alias (e.g. dev-)"
  default     = ""
}

variable "alias_name" {
  type        = string
  description = "Suffix for the alias (full: alias/<prefix><suffix>)"
  default     = "cognito-secrets"
}

variable "deletion_window_in_days" {
  type        = number
  description = "Waiting period before key deletion"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to KMS resources"
  default     = {}
}
