variable "name_prefix" {
  type        = string
  description = "Prefix for all Cognito resource names"
  default     = ""
}

variable "api_resource_server_identifier" {
  type        = string
  description = "URI identifier for the API resource server (e.g. https://api.mahizh.click)"
}

variable "resource_server_scopes" {
  type = list(object({
    name        = string
    description = string
  }))
  description = "OAuth2 scopes exposed by the resource server"
  default = [
    { name = "read", description = "Read access to the API" },
    { name = "write", description = "Write access to the API" },
  ]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all Cognito resources"
  default     = {}
}
