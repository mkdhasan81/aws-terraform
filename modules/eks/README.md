# Module: eks

Provisions an EKS cluster with a managed node group and security groups inside a VPC.

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "my-cluster"
  kubernetes_version = "1.29"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_role_arn      = module.iam.eks_node_role_arn
  tags               = { Environment = "dev" }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `cluster_name` | `string` | — | EKS cluster name (required) |
| `kubernetes_version` | `string` | `"1.29"` | Kubernetes version |
| `vpc_id` | `string` | — | VPC ID (required) |
| `private_subnet_ids` | `list(string)` | — | Private subnet IDs (required) |
| `cluster_role_arn` | `string` | — | IAM role ARN for EKS control plane (required) |
| `node_role_arn` | `string` | — | IAM role ARN for node group (required) |
| `node_instance_types` | `list(string)` | `["t3.medium"]` | Worker node instance types |
| `node_min_size` | `number` | `1` | Minimum node count |
| `node_max_size` | `number` | `3` | Maximum node count |
| `node_desired_size` | `number` | `2` | Desired node count |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
|---|---|
| `cluster_endpoint` | EKS cluster API endpoint |
| `cluster_name` | EKS cluster name |
| `cluster_security_group_id` | Cluster security group ID |
