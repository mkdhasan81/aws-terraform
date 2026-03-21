variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
  default     = "1.29"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the EKS cluster will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the EKS cluster and worker nodes"
}

variable "cluster_role_arn" {
  type        = string
  description = "IAM role ARN for the EKS cluster control plane"
}

variable "node_role_arn" {
  type        = string
  description = "IAM role ARN for the EKS worker node group"
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types for EKS worker nodes"
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 3
}

variable "node_desired_size" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2

  validation {
    condition     = var.node_desired_size >= 1
    error_message = "node_desired_size must be at least 1."
  }
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Enable public access to the EKS cluster API endpoint"
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to access the public EKS API endpoint"
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all EKS resources"
  default     = {}
}
