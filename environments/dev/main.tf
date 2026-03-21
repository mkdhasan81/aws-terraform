locals {
  env  = "dev"
  name = local.env

  common_tags = merge(var.tags, {
    Environment = local.env
    ManagedBy   = "terraform"
    Region      = var.aws_region
  })
}

module "vpc" {
  source = "../../modules/vpc"

  name           = local.name
  vpc_cidr_block = var.vpc_cidr_block
  tags           = local.common_tags
}

module "iam_lambda" {
  source = "../../modules/iam/lambda"

  name_prefix = "${local.env}-"
  tags        = local.common_tags
}

module "lambda" {
  source = "../../modules/lambda"

  function_name           = var.lambda_function_name
  runtime                 = var.lambda_runtime
  handler                 = var.lambda_handler
  memory_size             = var.lambda_memory_size
  timeout                 = var.lambda_timeout
  environment_variables   = var.lambda_environment_variables
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  vpc_cidr_block          = module.vpc.vpc_cidr_block
  lambda_role_arn         = module.iam_lambda.role_arn
  deployment_package_path = var.lambda_deployment_package_path
  tags                    = local.common_tags
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  name                 = var.lambda_function_name
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  stage_name           = local.env
  throttling_rate      = var.api_throttling_rate
  throttling_burst     = var.api_throttling_burst
  tags                 = local.common_tags
}
