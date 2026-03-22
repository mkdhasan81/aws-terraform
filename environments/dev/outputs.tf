output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = module.iam_lambda.role_arn
}

output "api_gateway_url" {
  description = "Invoke URL for the API Gateway stage"
  value       = module.api_gateway.invoke_url
}

output "api_gateway_id" {
  description = "ID of the REST API"
  value       = module.api_gateway.api_id
}

output "authorizer_function_name" {
  description = "Name of the API Gateway authorizer Lambda"
  value       = module.authorizer.function_name
}
