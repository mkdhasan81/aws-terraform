output "api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "invoke_url" {
  description = "Invoke URL for the deployed stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway (used for Lambda permissions)"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "log_group_name" {
  description = "CloudWatch log group name for API Gateway access logs"
  value       = aws_cloudwatch_log_group.api_gw.name
}
