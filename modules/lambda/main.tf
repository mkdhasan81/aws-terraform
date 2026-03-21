locals {
  use_placeholder = var.deployment_package_path == ""
}

# Placeholder zip when no deployment package is provided
data "archive_file" "placeholder" {
  count       = local.use_placeholder ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"

  source {
    content  = "def handler(event, context):\n    return {'statusCode': 200, 'body': 'placeholder'}\n"
    filename = "index.py"
  }
}

# Lambda Security Group — deny all inbound, allow outbound to VPC only
resource "aws_security_group" "lambda" {
  name        = "${var.function_name}-sg"
  description = "Lambda function security group: deny inbound, allow outbound to VPC"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow outbound to VPC CIDR"
  }

  tags = merge(var.tags, { Name = "${var.function_name}-sg" })
}

# Lambda Function
resource "aws_lambda_function" "main" {
  function_name = var.function_name
  role          = var.lambda_role_arn
  runtime       = var.runtime
  handler       = var.handler
  memory_size   = var.memory_size
  timeout       = var.timeout

  filename = local.use_placeholder ? data.archive_file.placeholder[0].output_path : var.deployment_package_path

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = var.tags
}
