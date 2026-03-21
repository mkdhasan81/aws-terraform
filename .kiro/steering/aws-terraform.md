---
inclusion: manual
---

# AWS + Terraform Conventions

## Authentication

Always confirm how the user authenticates to AWS before running any Terraform commands:

**Prompt the user:**
> "Do you have a long-term IAM access key + secret, or are you using federated/SSO login (e.g. Okta, ADFS, awssaml2)?"

- **Long-term keys** → `aws configure` (writes to `~/.aws/credentials`)
- **Federated/SSO** → use `awssaml2`, `aws sso login`, or equivalent to obtain temporary session tokens first
- Terraform picks up credentials automatically from `~/.aws/credentials`, environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), or instance profiles

## Terraform Workflow

Always follow this order:

```bash
aws configure          # set up credentials first
terraform init         # download providers and modules
terraform validate     # check config is valid
terraform fmt -recursive  # ensure canonical formatting
terraform plan         # preview changes
terraform apply        # deploy
```

## IAM Permissions Checklist

Before `terraform apply`, confirm the IAM user/role has permissions for all services in scope. Common ones for this workspace:

- `ec2:*` — VPC, subnets, IGW, NAT, security groups
- `eks:*` — EKS cluster and node groups
- `iam:*` — roles, policies, attachments
- `lambda:*` — Lambda functions
- `sts:AssumeRole` — for cross-service role assumptions

## Module Structure Convention

This workspace uses a 4-module pattern:

```
modules/vpc      — networking (VPC, subnets, IGW, NAT, route tables)
modules/iam      — IAM roles and policy attachments
modules/eks      — EKS cluster and managed node groups
modules/lambda   — Lambda functions inside VPC
```

Root `main.tf` composes all modules, passing VPC and IAM outputs into EKS and Lambda.

## Terraform Version

- Minimum required: `>= 1.5.0`
- AWS provider: `~> 5.0`
- Installed via Homebrew (note: Homebrew only carries 1.5.7 due to BUSL license change)
- For newer versions, install via [tfenv](https://github.com/tfutils/tfenv) or the [official HashiCorp releases](https://releases.hashicorp.com/terraform/)

## State Backend

Default is local state (`terraform.tfstate`). For team/production use, switch to S3:

```hcl
backend "s3" {
  bucket = "your-tfstate-bucket"
  key    = "infra/terraform.tfstate"
  region = "us-east-1"
}
```

Pass backend config at init time: `terraform init -backend-config=backend.hcl`
