output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function (used by API Gateway)"
  value       = aws_lambda_function.this.invoke_arn
}

output "security_group_id" {
  description = "Security group ID for the Lambda function"
  value       = aws_security_group.this.id
}
