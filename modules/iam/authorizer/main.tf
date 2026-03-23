locals {
  managed_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
}

# Role assumed by the authorizer Lambda itself
resource "aws_iam_role" "lambda" {
  name_prefix = "${var.name_prefix}authorizer-lambda-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "lambda" {
  for_each = toset(local.managed_policies)

  role       = aws_iam_role.lambda.name
  policy_arn = each.value
}

# Role assumed by API Gateway to invoke the authorizer Lambda
resource "aws_iam_role" "api_gateway_invoker" {
  name_prefix = "${var.name_prefix}apigw-authorizer-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "invoke_authorizer" {
  name = "invoke-authorizer-lambda"
  role = aws_iam_role.api_gateway_invoker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = var.authorizer_lambda_arn
    }]
  })
}
