output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.this.arn
}

output "client_id" {
  description = "M2M app client ID"
  value       = aws_cognito_user_pool_client.m2m.id
}

output "client_secret" {
  description = "M2M app client secret (sensitive)"
  value       = aws_cognito_user_pool_client.m2m.client_secret
  sensitive   = true
}

output "token_endpoint" {
  description = "OAuth2 token endpoint to request M2M tokens"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${split("_", aws_cognito_user_pool.this.id)[0]}.amazoncognito.com/oauth2/token"
}

output "m2m_token_url" {
  description = "OAuth2 token endpoint for machine-to-machine authentication using the client_credentials grant type"
  value       = "https://${aws_cognito_user_pool_domain.this.domain}.auth.${split("_", aws_cognito_user_pool.this.id)[0]}.amazoncognito.com/oauth2/token"
}

output "jwks_uri" {
  description = "JWKS endpoint — used by the Lambda authorizer to verify JWT signatures"
  value       = "https://cognito-idp.${split("_", aws_cognito_user_pool.this.id)[0]}.amazonaws.com/${aws_cognito_user_pool.this.id}/.well-known/jwks.json"
}

output "issuer" {
  description = "JWT issuer URL — used by the Lambda authorizer for iss claim validation"
  value       = "https://cognito-idp.${split("_", aws_cognito_user_pool.this.id)[0]}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}
