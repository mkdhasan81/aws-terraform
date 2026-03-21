variable "name_prefix" {
  type        = string
  description = "Prefix for IAM role names (e.g. 'dev-')"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all IAM resources"
  default     = {}
}
