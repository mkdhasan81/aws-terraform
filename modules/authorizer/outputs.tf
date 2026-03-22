output "invoke_arn" {
  description = "Invoke ARN of the authorizer Lambda (used by API Gateway)"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_name" {
  description = "Name of the authorizer Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the authorizer Lambda function"
  value       = aws_lambda_function.this.arn
}
