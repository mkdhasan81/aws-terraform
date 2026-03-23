variable "name_prefix" {
  type        = string
  description = "Prefix for the IAM role name (e.g. 'dev-')"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all IAM resources"
  default     = {}
}

variable "enable_kms_decrypt" {
  type        = bool
  description = "Whether to attach an inline kms:Decrypt policy to the Lambda role."
  default     = false
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key for decrypting secrets. Required when enable_kms_decrypt is true."
  default     = ""
}
