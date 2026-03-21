variable "name" {
  type        = string
  description = "Name prefix for all VPC resources"
  default     = "main"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "vpc_cidr_block must be valid CIDR notation."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs for subnet placement. Empty = auto-detect from region."
  default     = []
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets. Empty = computed from vpc_cidr_block."
  default     = []
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets. Empty = computed from vpc_cidr_block."
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

variable "cluster_name" {
  type        = string
  description = "EKS cluster name for Kubernetes subnet discovery tags. Empty = no tags."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}
