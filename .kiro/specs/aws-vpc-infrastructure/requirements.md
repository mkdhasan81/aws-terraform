# Requirements Document

## Introduction

This feature provides a reusable Terraform-based infrastructure-as-code solution for provisioning an AWS Virtual Private Cloud (VPC) configured to host private resources. The VPC supports deploying Amazon EKS clusters and AWS Lambda functions with proper network isolation, IAM roles, and security policies. The implementation is parameterized and modular so it can be reused across environments and projects without hardcoding.

## Glossary

- **VPC_Module**: The Terraform module responsible for creating and configuring the AWS Virtual Private Cloud and its associated networking resources (subnets, route tables, NAT gateways, internet gateways).
- **EKS_Module**: The Terraform module responsible for provisioning an Amazon Elastic Kubernetes Service cluster within the VPC, including node groups and associated networking configuration.
- **Lambda_Module**: The Terraform module responsible for deploying AWS Lambda functions inside the VPC with proper subnet and security group attachments.
- **IAM_Module**: The Terraform module responsible for creating IAM roles, policies, and instance profiles required by EKS, Lambda, and other VPC resources.
- **Private_Subnet**: A subnet within the VPC that does not have a direct route to an internet gateway. Outbound internet access is provided through a NAT gateway.
- **Public_Subnet**: A subnet within the VPC that has a direct route to an internet gateway, used for NAT gateways and load balancers.
- **NAT_Gateway**: A managed AWS network address translation service that enables resources in private subnets to access the internet for outbound traffic while remaining unreachable from the internet.
- **Security_Group**: An AWS virtual firewall that controls inbound and outbound traffic for resources within the VPC.
- **Terraform_Configuration**: The collection of Terraform files (.tf) that define the infrastructure resources, variables, and outputs.

## Requirements

### Requirement 1: VPC Provisioning

**User Story:** As a platform engineer, I want to provision a private AWS VPC with configurable CIDR blocks and subnets, so that I can host resources in an isolated network environment.

#### Acceptance Criteria

1. THE VPC_Module SHALL create an AWS VPC with a configurable CIDR block provided as a Terraform variable.
2. THE VPC_Module SHALL create Private_Subnets across a configurable number of availability zones.
3. THE VPC_Module SHALL create Public_Subnets across the same availability zones used by Private_Subnets.
4. THE VPC_Module SHALL enable DNS support and DNS hostnames on the VPC.
5. THE VPC_Module SHALL apply configurable tags to all created resources for identification and cost tracking.

### Requirement 2: Internet and NAT Gateway Configuration

**User Story:** As a platform engineer, I want private subnets to have outbound internet access through NAT gateways, so that resources can pull dependencies and updates without being publicly accessible.

#### Acceptance Criteria

1. THE VPC_Module SHALL create an internet gateway and attach it to the VPC.
2. THE VPC_Module SHALL create at least one NAT_Gateway in a Public_Subnet with an associated Elastic IP address.
3. THE VPC_Module SHALL create a route table for Private_Subnets that routes outbound internet traffic (0.0.0.0/0) through the NAT_Gateway.
4. THE VPC_Module SHALL create a route table for Public_Subnets that routes internet traffic (0.0.0.0/0) through the internet gateway.
5. THE VPC_Module SHALL associate each Private_Subnet with the private route table and each Public_Subnet with the public route table.

### Requirement 3: EKS Cluster Provisioning

**User Story:** As a platform engineer, I want to deploy an EKS cluster within the VPC, so that I can run containerized workloads in a managed Kubernetes environment.

#### Acceptance Criteria

1. THE EKS_Module SHALL create an EKS cluster with a configurable Kubernetes version provided as a Terraform variable.
2. THE EKS_Module SHALL deploy the EKS cluster control plane into the Private_Subnets of the VPC.
3. THE EKS_Module SHALL create a managed node group with configurable instance types, minimum size, maximum size, and desired size provided as Terraform variables.
4. THE EKS_Module SHALL deploy worker nodes into the Private_Subnets of the VPC.
5. THE EKS_Module SHALL create a Security_Group for the EKS cluster that allows communication between the control plane and worker nodes.
6. THE EKS_Module SHALL apply configurable tags to all EKS resources including the Kubernetes-required tags for subnet discovery.

### Requirement 4: Lambda VPC Integration

**User Story:** As a platform engineer, I want to deploy Lambda functions inside the VPC, so that Lambda functions can access private resources such as databases and internal services.

#### Acceptance Criteria

1. THE Lambda_Module SHALL create a Lambda function configured to run within the Private_Subnets of the VPC.
2. THE Lambda_Module SHALL accept a configurable runtime, handler, memory size, and timeout provided as Terraform variables.
3. THE Lambda_Module SHALL create a Security_Group for the Lambda function that restricts inbound traffic and allows outbound traffic to VPC resources.
4. THE Lambda_Module SHALL accept a configurable path to the Lambda deployment package as a Terraform variable.
5. WHEN no deployment package path is provided, THE Lambda_Module SHALL create a placeholder Lambda function with a minimal handler.

### Requirement 5: IAM Roles and Policies

**User Story:** As a platform engineer, I want IAM roles and policies provisioned with least-privilege permissions, so that each resource has only the access it needs to operate.

#### Acceptance Criteria

1. THE IAM_Module SHALL create an IAM role for the EKS cluster with the AmazonEKSClusterPolicy attached.
2. THE IAM_Module SHALL create an IAM role for EKS worker nodes with the AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, and AmazonEC2ContainerRegistryReadOnly policies attached.
3. THE IAM_Module SHALL create an IAM role for Lambda functions with the AWSLambdaVPCAccessExecutionRole policy attached.
4. THE IAM_Module SHALL configure each IAM role with an assume-role trust policy scoped to the specific AWS service (eks.amazonaws.com, ec2.amazonaws.com, lambda.amazonaws.com).
5. THE IAM_Module SHALL output the ARNs of all created IAM roles for use by other modules.

### Requirement 6: Reusable and Parameterized Configuration

**User Story:** As a platform engineer, I want the Terraform configuration to be modular and parameterized, so that I can reuse it across multiple environments and projects without modifying the source code.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL organize resources into separate modules for VPC, EKS, Lambda, and IAM.
2. THE Terraform_Configuration SHALL expose all environment-specific values (region, CIDR blocks, instance types, cluster name) as input variables with sensible defaults.
3. THE Terraform_Configuration SHALL define output values for VPC ID, subnet IDs, EKS cluster endpoint, EKS cluster name, and Lambda function ARN.
4. THE Terraform_Configuration SHALL include a variables file with descriptions and type constraints for each input variable.
5. THE Terraform_Configuration SHALL use a configurable Terraform backend so that state can be stored locally or remotely.

### Requirement 7: Security Group Configuration

**User Story:** As a platform engineer, I want security groups configured with restrictive rules, so that network traffic between resources is controlled and limited to what is necessary.

#### Acceptance Criteria

1. THE VPC_Module SHALL create a default Security_Group for the VPC that denies all inbound traffic and allows all outbound traffic.
2. THE EKS_Module SHALL create a Security_Group that allows inbound traffic on port 443 from worker nodes to the EKS control plane.
3. THE EKS_Module SHALL create a Security_Group that allows all traffic between worker nodes within the cluster.
4. THE Lambda_Module SHALL create a Security_Group that allows outbound traffic to the VPC CIDR block and denies all inbound traffic.
5. IF a Security_Group rule references another Security_Group, THEN THE Terraform_Configuration SHALL use security group ID references instead of CIDR blocks.

### Requirement 8: Terraform Setup and Validation

**User Story:** As a platform engineer, I want the Terraform configuration to be validated and ready to apply, so that I can deploy the infrastructure with confidence.

#### Acceptance Criteria

1. THE Terraform_Configuration SHALL specify a minimum required Terraform version and required AWS provider version.
2. THE Terraform_Configuration SHALL pass `terraform validate` without errors.
3. THE Terraform_Configuration SHALL pass `terraform fmt -check` without formatting differences.
4. THE Terraform_Configuration SHALL include a README file documenting input variables, output values, and usage instructions.
