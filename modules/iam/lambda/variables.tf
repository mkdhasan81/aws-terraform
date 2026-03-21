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
