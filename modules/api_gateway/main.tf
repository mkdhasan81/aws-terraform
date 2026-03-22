locals {
  api_name = "${var.name}-api"

  # Both root and proxy resource IDs wired to the same Lambda
  resources = {
    root  = aws_api_gateway_rest_api.this.root_resource_id
    proxy = aws_api_gateway_resource.proxy.id
  }

  # Use CUSTOM auth when authorizer is provided, else NONE
  authorization = var.authorizer_invoke_arn != "" ? "CUSTOM" : "NONE"
}

resource "aws_api_gateway_rest_api" "this" {
  name        = local.api_name
  description = "REST API for ${var.name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{proxy+}"
}

# TOKEN-based Lambda authorizer — only created when authorizer_invoke_arn is set
resource "aws_api_gateway_authorizer" "this" {
  count = var.authorizer_invoke_arn != "" ? 1 : 0

  name                             = "${var.name}-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.this.id
  authorizer_uri                   = var.authorizer_invoke_arn
  authorizer_credentials           = var.authorizer_role_arn
  type                             = "TOKEN"
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = var.authorizer_ttl_seconds
}

resource "aws_api_gateway_method" "this" {
  for_each = local.resources

  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = each.value
  http_method   = "ANY"
  authorization = local.authorization
  authorizer_id = var.authorizer_invoke_arn != "" ? aws_api_gateway_authorizer.this[0].id : null
}

resource "aws_api_gateway_integration" "this" {
  for_each = local.resources

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = each.value
  http_method             = aws_api_gateway_method.this[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.this,
      aws_api_gateway_method.this,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.this]
}

# CloudWatch log group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api-gateway/${local.api_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      authStatus     = "$context.authorizer.authorized"
    })
  }

  tags = var.tags
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = var.throttling_rate
    throttling_burst_limit = var.throttling_burst
    metrics_enabled        = true
    logging_level          = "INFO"
  }
}

# Allow API Gateway to invoke the backend Lambda
resource "aws_lambda_permission" "this" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# Allow API Gateway to invoke the authorizer Lambda
resource "aws_lambda_permission" "authorizer" {
  count = var.authorizer_invoke_arn != "" ? 1 : 0

  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/authorizers/*"
}
