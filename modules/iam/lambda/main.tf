locals {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
  ]
}

resource "aws_iam_role" "this" {
  name_prefix        = "${var.name_prefix}lambda-"
  assume_role_policy = local.assume_role_policy

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(local.managed_policies)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
