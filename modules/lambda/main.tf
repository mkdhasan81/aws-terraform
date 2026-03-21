locals {
  use_placeholder = var.deployment_package_path == ""
  package_path    = local.use_placeholder ? data.archive_file.placeholder[0].output_path : var.deployment_package_path
  package_hash    = local.use_placeholder ? data.archive_file.placeholder[0].output_base64sha256 : filebase64sha256(var.deployment_package_path)
}

data "archive_file" "placeholder" {
  count       = local.use_placeholder ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"

  source {
    content  = "def handler(event, context):\n    return {'statusCode': 200, 'body': 'Hello from ${var.function_name}'}\n"
    filename = "index.py"
  }
}

resource "aws_security_group" "this" {
  name        = "${var.function_name}-sg"
  description = "Lambda SG: deny all inbound, allow outbound to VPC only"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow outbound to VPC CIDR only"
  }

  tags = merge(var.tags, { Name = "${var.function_name}-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = var.lambda_role_arn
  runtime          = var.runtime
  handler          = var.handler
  memory_size      = var.memory_size
  timeout          = var.timeout
  filename         = local.package_path
  source_code_hash = local.package_hash

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [var.environment_variables] : []
    content {
      variables = environment.value
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.this.id]
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = false      # set to true in production
    ignore_changes  = [filename] # prevent redeploy on unrelated plan runs
  }
}
