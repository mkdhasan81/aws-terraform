# Module: lambda

Deploys a Lambda function inside a VPC with a dedicated security group. Creates a placeholder handler when no deployment package is provided.

## Usage

```hcl
module "lambda" {
  source = "../../modules/lambda"

  function_name      = "my-function"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_cidr_block     = module.vpc.vpc_cidr_block
  lambda_role_arn    = module.iam.lambda_role_arn
  tags               = { Environment = "dev" }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `function_name` | `string` | — | Lambda function name (required) |
| `runtime` | `string` | `"python3.12"` | Lambda runtime |
| `handler` | `string` | `"index.handler"` | Lambda handler |
| `memory_size` | `number` | `128` | Memory in MB |
| `timeout` | `number` | `30` | Timeout in seconds |
| `vpc_id` | `string` | — | VPC ID (required) |
| `private_subnet_ids` | `list(string)` | — | Private subnet IDs (required) |
| `vpc_cidr_block` | `string` | — | VPC CIDR for security group egress (required) |
| `lambda_role_arn` | `string` | — | IAM role ARN (required) |
| `deployment_package_path` | `string` | `""` | Path to zip package (empty = placeholder) |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

## Outputs

| Name | Description |
|---|---|
| `function_arn` | Lambda function ARN |
| `function_name` | Lambda function name |
| `security_group_id` | Lambda security group ID |
