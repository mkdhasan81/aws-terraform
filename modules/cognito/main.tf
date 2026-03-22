locals {
  pool_name   = "${var.name_prefix}api-user-pool"
  domain_name = "${var.name_prefix}auth"
}

# Cognito User Pool — acts as the authorization server
resource "aws_cognito_user_pool" "this" {
  name = local.pool_name

  # M2M doesn't use password auth — disable user sign-up
  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  tags = var.tags
}

# Resource server — defines the API and its scopes
resource "aws_cognito_resource_server" "this" {
  user_pool_id = aws_cognito_user_pool.this.id
  identifier   = var.api_resource_server_identifier
  name         = "${var.name_prefix}api-resource-server"

  dynamic "scope" {
    for_each = var.resource_server_scopes
    content {
      scope_name        = scope.value.name
      scope_description = scope.value.description
    }
  }
}

# App client — the M2M client that requests tokens
resource "aws_cognito_user_pool_client" "m2m" {
  name         = "${var.name_prefix}m2m-client"
  user_pool_id = aws_cognito_user_pool.this.id

  # client_credentials flow — no user interaction
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_flows_user_pool_client = true
  generate_secret                      = true

  allowed_oauth_scopes = [
    for s in var.resource_server_scopes :
    "${var.api_resource_server_identifier}/${s.name}"
  ]

  supported_identity_providers = ["COGNITO"]

  depends_on = [aws_cognito_resource_server.this]
}

# Cognito domain — required for the /oauth2/token endpoint
resource "aws_cognito_user_pool_domain" "this" {
  domain       = local.domain_name
  user_pool_id = aws_cognito_user_pool.this.id
}
