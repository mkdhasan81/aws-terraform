output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.main.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.main.function_name
}

output "security_group_id" {
  description = "Security group ID for the Lambda function"
  value       = aws_security_group.lambda.id
}
