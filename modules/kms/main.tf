resource "aws_kms_key" "this" {
  description              = "Encrypts Cognito M2M credentials"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  deletion_window_in_days  = var.deletion_window_in_days
  tags                     = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}${var.alias_name}"
  target_key_id = aws_kms_key.this.key_id
}
