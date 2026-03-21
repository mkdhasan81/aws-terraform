locals {
  common_tags = merge(var.tags, {
    ManagedBy   = "terraform"
    Environment = "dev"
    Module      = "aws-terraform"
  })
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr_block       = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  enable_dns_support   = true
  enable_dns_hostnames = true
  cluster_name         = var.cluster_name
  tags                 = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  tags = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  cluster_role_arn    = module.iam.eks_cluster_role_arn
  node_role_arn       = module.iam.eks_node_role_arn
  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
  tags                = local.common_tags
}

module "lambda" {
  source = "../../modules/lambda"

  function_name           = var.lambda_function_name
  runtime                 = var.lambda_runtime
  handler                 = var.lambda_handler
  memory_size             = var.lambda_memory_size
  timeout                 = var.lambda_timeout
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  vpc_cidr_block          = module.vpc.vpc_cidr_block
  lambda_role_arn         = module.iam.lambda_role_arn
  deployment_package_path = var.lambda_deployment_package_path
  tags                    = local.common_tags
}
