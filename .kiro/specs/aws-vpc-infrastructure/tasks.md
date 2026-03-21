# Implementation Plan: AWS VPC Infrastructure

## Overview

Implement a modular Terraform infrastructure-as-code solution composed of four child modules (vpc, iam, eks, lambda) wired together by a root module. Tests are written in Python using pytest and Hypothesis for property-based testing.

## Tasks

- [x] 1. Set up project structure and provider configuration
  - Create the directory tree: `modules/vpc`, `modules/iam`, `modules/eks`, `modules/lambda`
  - Create `providers.tf` with `required_version`, `required_providers` (AWS provider), and a configurable backend block defaulting to local state
  - _Requirements: 8.1, 6.5_

- [ ] 2. Implement the IAM module
  - [-] 2.1 Create `modules/iam/variables.tf`, `modules/iam/main.tf`, and `modules/iam/outputs.tf`
    - Define `tags` input variable with type and description
    - Create EKS cluster IAM role with `eks.amazonaws.com` trust policy and attach `AmazonEKSClusterPolicy`
    - Create EKS node IAM role with `ec2.amazonaws.com` trust policy and attach `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`
    - Create Lambda IAM role with `lambda.amazonaws.com` trust policy and attach `AWSLambdaVPCAccessExecutionRole`
    - Output `eks_cluster_role_arn`, `eks_node_role_arn`, `lambda_role_arn`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ] 2.2 Write property test for IAM trust policy scoping (Property 6)
    - **Property 6: IAM trust policy scoping**
    - Parse `modules/iam/main.tf` with python-hcl2 and verify each role's assume-role policy contains exactly one service principal matching the intended service
    - **Validates: Requirements 5.4**

- [ ] 3. Implement the VPC module
  - [ ] 3.1 Create `modules/vpc/variables.tf` with all inputs: `vpc_cidr_block`, `availability_zones`, `private_subnet_cidrs`, `public_subnet_cidrs`, `enable_dns_support`, `enable_dns_hostnames`, `tags`, `cluster_name` — each with type, description, and default; add `validation` block on `vpc_cidr_block`
    - _Requirements: 1.1, 6.4_

  - [ ] 3.2 Create `modules/vpc/main.tf` with VPC, subnets, internet gateway, NAT gateway + EIP, route tables, and route table associations
    - VPC with `enable_dns_support` and `enable_dns_hostnames`
    - Private and public subnets across provided AZs using `cidrsubnet()` defaults
    - Internet gateway attached to VPC; public route table with `0.0.0.0/0 → IGW`
    - NAT gateway in first public subnet with EIP; private route table with `0.0.0.0/0 → NAT`
    - Associate each private subnet with private RT and each public subnet with public RT
    - Default security group denying all inbound and allowing all outbound
    - Apply EKS Kubernetes discovery tags to subnets when `cluster_name` is set
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.2, 2.3, 2.4, 2.5, 7.1_

  - [ ] 3.3 Create `modules/vpc/outputs.tf` with `vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `vpc_cidr_block`, `nat_gateway_id`, `default_security_group_id`
    - _Requirements: 6.3_

  - [ ] 3.4 Write property test for VPC CIDR pass-through (Property 1)
    - **Property 1: VPC CIDR pass-through**
    - Use Hypothesis to generate valid CIDR strings; parse HCL and assert VPC `cidr_block` equals input
    - **Validates: Requirements 1.1**

  - [ ] 3.5 Write property test for subnet AZ symmetry (Property 2)
    - **Property 2: Subnet AZ symmetry**
    - Use Hypothesis to generate lists of AZ names; assert exactly N private and N public subnets are defined and their AZ sets match
    - **Validates: Requirements 1.2, 1.3**

  - [ ] 3.6 Write property test for route table association completeness (Property 4)
    - **Property 4: Route table association completeness**
    - Use Hypothesis to vary subnet counts; assert count of private RT associations equals count of private subnets and same for public
    - **Validates: Requirements 2.5**

- [ ] 4. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement the EKS module
  - [ ] 5.1 Create `modules/eks/variables.tf` with all inputs: `cluster_name`, `kubernetes_version`, `vpc_id`, `private_subnet_ids`, `cluster_role_arn`, `node_role_arn`, `node_instance_types`, `node_min_size`, `node_max_size`, `node_desired_size`, `tags` — each with type, description, and default where applicable; add `validation` block enforcing `min_size <= desired_size <= max_size`
    - _Requirements: 3.1, 3.3, 6.4_

  - [ ] 5.2 Create `modules/eks/main.tf` with EKS cluster, managed node group, and security groups
    - EKS cluster using `private_subnet_ids` and `cluster_role_arn`
    - Managed node group with configurable instance types and scaling sizes deployed into private subnets
    - Security group allowing port 443 ingress from worker nodes to control plane
    - Security group allowing all traffic between worker nodes (self-referencing rule using SG ID)
    - Apply configurable tags including Kubernetes-required tags
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 7.2, 7.3, 7.5_

  - [ ] 5.3 Create `modules/eks/outputs.tf` with `cluster_endpoint`, `cluster_name`, `cluster_security_group_id`
    - _Requirements: 6.3_

  - [ ] 5.4 Write property test for configurable resource parameters pass-through (Property 5)
    - **Property 5: Configurable resource parameters pass-through**
    - Use Hypothesis to generate valid combinations of Kubernetes version, instance types, and node scaling sizes (min ≤ desired ≤ max); parse HCL and assert each attribute matches the input
    - **Validates: Requirements 3.1, 3.3, 4.2**

  - [ ] 5.5 Write property test for security group references use IDs (Property 8)
    - **Property 8: Security group references use IDs**
    - Parse all module HCL files and assert no security group rule uses `cidr_blocks` to reference another security group — only `source_security_group_id` or `security_groups`
    - **Validates: Requirements 7.5**

- [ ] 6. Implement the Lambda module
  - [ ] 6.1 Create `modules/lambda/variables.tf` with all inputs: `function_name`, `runtime`, `handler`, `memory_size`, `timeout`, `vpc_id`, `private_subnet_ids`, `vpc_cidr_block`, `lambda_role_arn`, `deployment_package_path`, `tags` — each with type, description, and default where applicable
    - _Requirements: 4.2, 6.4_

  - [ ] 6.2 Create `modules/lambda/main.tf` with Lambda function and security group
    - Security group denying all inbound and allowing outbound to `vpc_cidr_block` only
    - Lambda function with `vpc_config` referencing `private_subnet_ids` and the security group
    - Use `archive_file` data source to create a minimal placeholder zip when `deployment_package_path` is empty; use the provided path otherwise
    - _Requirements: 4.1, 4.3, 4.4, 4.5, 7.4, 7.5_

  - [ ] 6.3 Create `modules/lambda/outputs.tf` with `function_arn`, `function_name`, `security_group_id`
    - _Requirements: 6.3_

- [ ] 7. Implement the root module
  - [ ] 7.1 Create `variables.tf` at the root with all environment-specific variables: `aws_region`, `vpc_cidr_block`, `availability_zones`, `cluster_name`, `kubernetes_version`, `node_instance_types`, `node_min_size`, `node_max_size`, `node_desired_size`, `lambda_function_name`, `lambda_runtime`, `lambda_handler`, `lambda_memory_size`, `lambda_timeout`, `lambda_deployment_package_path`, `tags` — each with type, description, and sensible default
    - _Requirements: 6.2, 6.4_

  - [ ] 7.2 Create `main.tf` at the root composing all four modules
    - Instantiate `module "vpc"`, `module "iam"`, `module "eks"`, `module "lambda"` passing outputs from vpc and iam into eks and lambda
    - Include `locals` block with `common_tags` merging user tags with `ManagedBy = "terraform"` and `Module = "aws-vpc-infrastructure"`
    - _Requirements: 6.1, 1.5, 3.6_

  - [ ] 7.3 Create `outputs.tf` at the root exposing `vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `eks_cluster_endpoint`, `eks_cluster_name`, `lambda_function_arn`
    - _Requirements: 6.3_

- [ ] 8. Add variable validation blocks and write unit tests
  - [ ] 8.1 Add `validation` blocks to key root variables: `vpc_cidr_block` (valid CIDR), `node_desired_size` (≥ 1), and the node scaling constraint (`min ≤ desired ≤ max`)
    - _Requirements: 8.2_

  - [ ] 8.2 Create `tests/conftest.py` and `tests/test_structure.py` using pytest and python-hcl2
    - Assert module directories exist (`modules/vpc`, `modules/iam`, `modules/eks`, `modules/lambda`)
    - Assert `providers.tf` contains `required_version` and `required_providers` blocks
    - Assert VPC resource has `enable_dns_support = true` and `enable_dns_hostnames = true`
    - Assert IGW resource exists; NAT gateway exists with EIP; private RT has `0.0.0.0/0` → NAT; public RT has `0.0.0.0/0` → IGW
    - Assert EKS cluster `subnet_ids` references private subnets; security group rules include port 443 ingress and self-referencing rule
    - Assert Lambda `vpc_config` references private subnets; Lambda resource exists when `deployment_package_path` is empty
    - Assert IAM policy attachments match requirements 5.1–5.3; IAM module outputs include all three role ARNs
    - Assert root `outputs.tf` defines `vpc_id`, `private_subnet_ids`, `eks_cluster_endpoint`, `eks_cluster_name`, `lambda_function_arn`
    - Assert default SG denies inbound; Lambda SG denies inbound and allows outbound to VPC CIDR
    - Assert `README.md` exists
    - _Requirements: 1.4, 2.1, 2.2, 2.3, 2.4, 3.2, 3.5, 4.1, 4.5, 5.1, 5.2, 5.3, 5.5, 6.1, 6.3, 7.1, 7.2, 7.3, 7.4, 8.1, 8.4_

- [ ] 9. Write property-based tests
  - [ ] 9.1 Write property test for tag propagation (Property 3)
    - **Property 3: Tag propagation**
    - Use Hypothesis to generate arbitrary tag maps; parse all module HCL files and assert every resource block includes all key-value pairs from the input tag map
    - **Validates: Requirements 1.5, 3.6**

  - [ ] 9.2 Write property test for variable definitions completeness (Property 7)
    - **Property 7: Variable definitions completeness**
    - Parse all `variables.tf` files across root and modules; for every variable block assert both `description` and `type` attributes are present
    - **Validates: Requirements 6.4**

- [ ] 10. Create README and run final validation
  - [ ] 10.1 Create `README.md` documenting input variables, output values, module structure, prerequisites, and usage instructions
    - _Requirements: 8.4_

  - [ ] 10.2 Verify `terraform fmt -check` passes by ensuring all `.tf` files use canonical HCL formatting
    - _Requirements: 8.3_

- [ ] 11. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use Hypothesis (Python) with python-hcl2 for HCL parsing
- Unit tests use pytest with python-hcl2
- Checkpoints ensure incremental validation before proceeding
