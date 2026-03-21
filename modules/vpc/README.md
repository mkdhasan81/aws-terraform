# Module: vpc

Creates an AWS VPC with public/private subnets across multiple AZs, internet gateway, NAT gateway, route tables, and a default security group.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr_block     = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  cluster_name       = "my-cluster"
  tags               = { Environment = "dev" }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `vpc_cidr_block` | `string` | `"10.0.0.0/16"` | CIDR block for the VPC |
| `availability_zones` | `list(string)` | `[]` | AZs (auto-detected if empty) |
| `private_subnet_cidrs` | `list(string)` | `[]` | Private subnet CIDRs (computed if empty) |
| `public_subnet_cidrs` | `list(string)` | `[]` | Public subnet CIDRs (computed if empty) |
| `enable_dns_support` | `bool` | `true` | Enable DNS support |
| `enable_dns_hostnames` | `bool` | `true` | Enable DNS hostnames |
| `cluster_name` | `string` | `""` | EKS cluster name for subnet discovery tags |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
|---|---|
| `vpc_id` | VPC ID |
| `private_subnet_ids` | Private subnet IDs |
| `public_subnet_ids` | Public subnet IDs |
| `vpc_cidr_block` | VPC CIDR block |
| `nat_gateway_id` | NAT gateway ID |
| `default_security_group_id` | Default security group ID |
