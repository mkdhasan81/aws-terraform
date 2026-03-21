# Module: iam

Creates IAM roles with least-privilege policies for EKS cluster, EKS worker nodes, and Lambda functions.

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  tags = { Environment = "dev" }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `tags` | `map(string)` | `{}` | Tags applied to all IAM resources |

## Outputs

| Name | Description |
|---|---|
| `eks_cluster_role_arn` | ARN of the EKS cluster IAM role |
| `eks_node_role_arn` | ARN of the EKS node group IAM role |
| `lambda_role_arn` | ARN of the Lambda execution IAM role |
