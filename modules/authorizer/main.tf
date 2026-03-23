locals {
  function_name = "${var.name_prefix}api-authorizer"
}

data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.module}/handler/index.py"
  output_path = "${path.module}/handler.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = local.function_name
  role             = var.role_arn
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      JWKS_URI       = var.jwks_uri
      ISSUER         = var.issuer
      REQUIRED_SCOPE = var.required_scope
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [filename]
  }
}
