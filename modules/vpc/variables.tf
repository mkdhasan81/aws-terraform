variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be a valid CIDR notation."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for subnet placement"
  default     = []
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets. If empty, computed from vpc_cidr_block."
  default     = []
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets. If empty, computed from vpc_cidr_block."
  default     = []
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS support on the VPC"
  default     = true
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames on the VPC"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name for Kubernetes subnet discovery tags"
  default     = ""
}
