output "lambda_role_arn" {
  description = "ARN of the IAM role for the authorizer Lambda"
  value       = aws_iam_role.lambda.arn
}

output "api_gateway_invoker_role_arn" {
  description = "ARN of the IAM role API Gateway assumes to invoke the authorizer"
  value       = aws_iam_role.api_gateway_invoker.arn
}
