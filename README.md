# AWS VPC Infrastructure

Modular Terraform configuration for provisioning an AWS VPC with EKS and Lambda support.

## Architecture

- **VPC module** — VPC, public/private subnets, IGW, NAT gateway, route tables, security group
- **IAM module** — IAM roles for EKS cluster, EKS nodes, and Lambda
- **EKS module** — EKS cluster, managed node group, security groups
- **Lambda module** — Lambda function inside VPC with security group

## Prerequisites

- Terraform >= 1.5.0
- AWS credentials configured (`aws configure` or environment variables)
- Sufficient IAM permissions to create VPC, EKS, Lambda, and IAM resources

## Usage

```hcl
terraform init
terraform plan
terraform apply
```

Override defaults with a `terraform.tfvars` file:

```hcl
aws_region   = "us-west-2"
cluster_name = "my-cluster"
tags = {
  Environment = "production"
  Team        = "platform"
}
```

## Input Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | `string` | `"us-east-1"` | AWS region |
| `vpc_cidr_block` | `string` | `"10.0.0.0/16"` | VPC CIDR block |
| `availability_zones` | `list(string)` | `[]` | AZs (auto-detected if empty) |
| `cluster_name` | `string` | `"main-cluster"` | EKS cluster name |
| `kubernetes_version` | `string` | `"1.29"` | Kubernetes version |
| `node_instance_types` | `list(string)` | `["t3.medium"]` | Worker node instance types |
| `node_min_size` | `number` | `1` | Min worker nodes |
| `node_max_size` | `number` | `3` | Max worker nodes |
| `node_desired_size` | `number` | `2` | Desired worker nodes |
| `lambda_function_name` | `string` | `"vpc-lambda"` | Lambda function name |
| `lambda_runtime` | `string` | `"python3.12"` | Lambda runtime |
| `lambda_handler` | `string` | `"index.handler"` | Lambda handler |
| `lambda_memory_size` | `number` | `128` | Lambda memory (MB) |
| `lambda_timeout` | `number` | `30` | Lambda timeout (seconds) |
| `lambda_deployment_package_path` | `string` | `""` | Path to Lambda zip (empty = placeholder) |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

## Outputs

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `private_subnet_ids` | Private subnet IDs |
| `public_subnet_ids` | Public subnet IDs |
| `eks_cluster_endpoint` | EKS cluster API endpoint |
| `eks_cluster_name` | EKS cluster name |
| `lambda_function_arn` | Lambda function ARN |

## Notes

- A single NAT gateway is created by default to minimize cost. For HA, extend the VPC module to create one per AZ.
- If `lambda_deployment_package_path` is empty, a minimal placeholder Python handler is deployed automatically.
- AWS accounts have a default limit of 5 EIPs per region; this configuration uses one.
- Not all instance types are available in all AZs — verify availability before selecting node instance types.
