# Implementation Plan: KMS Cognito M2M Auth

## Overview

Incrementally add KMS-based encryption for Cognito M2M credentials across the Terraform modules and the authorizer Lambda handler. Each task builds on the previous one, starting with the new KMS module, then modifying existing modules, updating the Lambda handler, wiring everything in the dev environment, and finally validating with property-based tests.

## Tasks

- [x] 1. Create the `modules/kms` module
  - [x] 1.1 Create `modules/kms/variables.tf` with `name_prefix`, `alias_name` (default `cognito-secrets`), `deletion_window_in_days` (default `30`), and `tags` variables
    - _Requirements: 1.2, 1.3, 1.6_
  - [x] 1.2 Create `modules/kms/main.tf` with `aws_kms_key` (symmetric, ENCRYPT_DECRYPT, key rotation enabled) and `aws_kms_alias` (`alias/${var.name_prefix}${var.alias_name}`)
    - _Requirements: 1.1, 1.2, 1.5_
  - [x] 1.3 Create `modules/kms/outputs.tf` exposing `key_arn`, `key_id`, and `alias_arn`
    - _Requirements: 1.4_

- [x] 2. Add `m2m_token_url` output to `modules/cognito`
  - [x] 2.1 Add a new `m2m_token_url` output in `modules/cognito/outputs.tf` with the same URL as `token_endpoint` and a description specifying `client_credentials` grant usage; retain the existing `token_endpoint` output
    - _Requirements: 5.1, 5.2, 5.4_

- [x] 3. Add conditional KMS Decrypt policies to IAM modules
  - [x] 3.1 Add optional `kms_key_arn` variable (default `""`) to `modules/iam/authorizer/variables.tf` and a conditional `aws_iam_role_policy.kms_decrypt` inline policy on `aws_iam_role.lambda` in `modules/iam/authorizer/main.tf`, created only when `kms_key_arn != ""`
    - _Requirements: 3.1, 3.2, 3.5_
  - [x] 3.2 Add optional `kms_key_arn` variable (default `""`) to `modules/iam/lambda/variables.tf` and a conditional `aws_iam_role_policy.kms_decrypt` inline policy on `aws_iam_role.this` in `modules/iam/lambda/main.tf`, created only when `kms_key_arn != ""`
    - _Requirements: 3.3, 3.4, 3.5_

- [x] 4. Add new variables and environment variables to `modules/authorizer`
  - [x] 4.1 Add `encrypted_client_secret`, `kms_key_arn`, and `m2m_token_url` variables (all `string`, default `""`) to `modules/authorizer/variables.tf`
    - _Requirements: 6.1, 6.2, 6.3_
  - [x] 4.2 Update `modules/authorizer/main.tf` to pass `ENCRYPTED_CLIENT_SECRET`, `KMS_KEY_ARN`, and `M2M_TOKEN_URL` as Lambda environment variables
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 5. Checkpoint — Validate Terraform modules
  - Ensure all Terraform modules are syntactically valid. Ask the user if questions arise.

- [x] 6. Implement `_decrypt_env` in the authorizer Lambda handler
  - [x] 6.1 Add the `_decrypted_cache` module-level dict and `_decrypt_env(env_var_name)` function to `modules/authorizer/handler/index.py` that reads ciphertext from `os.environ`, lazy-imports `boto3`, calls `kms.decrypt`, caches the plaintext, and returns it. If the env var is empty, return empty string without calling KMS.
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 7.1_
  - [x] 6.2 Write property test for decrypt result caching
    - **Property 4: Decrypt result caching**
    - **Validates: Requirements 4.2**
  - [x] 6.3 Write property test for KMS failure produces Deny policy
    - **Property 5: KMS failure produces Deny policy**
    - **Validates: Requirements 4.3**
  - [x] 6.4 Write property test for encrypt-then-decrypt round trip
    - **Property 3: Encrypt-then-decrypt round trip**
    - **Validates: Requirements 2.1, 4.1, 7.4**

- [x] 7. Wire everything together in `environments/dev/main.tf`
  - [x] 7.1 Add `module "kms"` call in `environments/dev/main.tf` with `name_prefix = "${local.env}-"` and `tags = local.common_tags`
    - _Requirements: 1.1, 1.2, 1.3_
  - [x] 7.2 Add `data "aws_kms_ciphertext" "client_secret"` data source using `module.kms.key_id` and `module.cognito.client_secret`
    - _Requirements: 2.1_
  - [x] 7.3 Update `module.authorizer` call to pass `encrypted_client_secret`, `kms_key_arn`, and `m2m_token_url`
    - _Requirements: 2.3, 2.4, 6.1, 6.2, 6.3_
  - [x] 7.4 Update `module.iam_authorizer` and `module.iam_lambda` calls to pass `kms_key_arn = module.kms.key_arn`
    - _Requirements: 3.1, 3.3_
  - [x] 7.5 Update `environments/dev/outputs.tf`: add `m2m_token_url` and `cognito_client_secret_encrypted` outputs, remove the plaintext `cognito_client_secret` output
    - _Requirements: 2.2, 5.3, 7.2_

- [x] 8. Checkpoint — Full integration validation
  - Ensure all Terraform files are syntactically valid and the Lambda handler has no syntax errors. Ask the user if questions arise.

- [x] 9. Property-based tests for Terraform logic
  - [x] 9.1 Write property test for KMS alias naming convention
    - **Property 1: KMS alias naming convention**
    - **Validates: Requirements 1.2**
  - [x] 9.2 Write property test for conditional KMS Decrypt policy scoping
    - **Property 2: Conditional KMS Decrypt policy is scoped to exact key ARN**
    - **Validates: Requirements 3.2, 3.4, 3.5**
  - [x] 9.3 Write property test for M2M token URL format
    - **Property 6: M2M token URL format**
    - **Validates: Requirements 5.1**
  - [x] 9.4 Write property test for no hardcoded credentials
    - **Property 7: No hardcoded credentials in source files**
    - **Validates: Requirements 7.1, 7.2**

- [x] 10. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Property-based tests use the `hypothesis` library (Python)
- Each property test maps to exactly one correctness property from the design document
- Checkpoints ensure incremental validation before moving to the next phase
