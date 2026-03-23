# Requirements Document

## Introduction

This feature adds AWS KMS encryption/decryption for sensitive credentials and switches the Cognito module to output the M2M (machine-to-machine) token URL derived from the Cognito domain, eliminating hardcoded credentials. Currently, the Cognito client secret is exposed as a plain-text Terraform output and the token endpoint is already constructed from the Cognito domain. The goal is to encrypt sensitive values (client secret, and optionally client ID) at rest using KMS, provide a decryption path in the authorizer Lambda or consuming services, and ensure the token endpoint output is clearly the M2M-specific OAuth2 `client_credentials` endpoint so callers never need to hardcode credentials.

## Glossary

- **KMS_Module**: A new Terraform module that provisions an AWS KMS customer-managed key (CMK) and associated alias used to encrypt and decrypt sensitive values.
- **KMS_Key**: The AWS KMS customer-managed symmetric encryption key created by the KMS_Module.
- **Cognito_Module**: The existing Terraform module (`modules/cognito`) that provisions the Cognito User Pool, resource server, M2M app client, and domain.
- **Authorizer_Lambda**: The existing Python Lambda function (`modules/authorizer/handler/index.py`) that validates Cognito-issued JWTs on API Gateway requests.
- **IAM_Authorizer_Module**: The existing Terraform module (`modules/iam/authorizer`) that manages IAM roles for the authorizer Lambda and API Gateway invoker.
- **IAM_Lambda_Module**: The existing Terraform module (`modules/iam/lambda`) that manages the IAM execution role for the backend Lambda.
- **Client_Secret_Ciphertext**: The KMS-encrypted form of the Cognito M2M app client secret, stored as a base64-encoded ciphertext blob.
- **M2M_Token_URL**: The OAuth2 token endpoint (`https://<domain>.auth.<region>.amazoncognito.com/oauth2/token`) used with the `client_credentials` grant type to obtain machine-to-machine access tokens.
- **Environment_Config**: The root Terraform configuration in `environments/dev/` that wires all modules together.

## Requirements

### Requirement 1: KMS Key Provisioning

**User Story:** As a platform engineer, I want a dedicated KMS customer-managed key provisioned via Terraform, so that I can encrypt sensitive Cognito credentials at rest without relying on hardcoded secrets.

#### Acceptance Criteria

1. THE KMS_Module SHALL create a symmetric KMS_Key with key usage set to ENCRYPT_DECRYPT.
2. THE KMS_Module SHALL create a KMS alias with a configurable name prefix (e.g. `alias/<env>-cognito-secrets`).
3. THE KMS_Module SHALL accept a `tags` variable and apply the tags to the KMS_Key and alias.
4. THE KMS_Module SHALL output the KMS_Key ARN and alias ARN.
5. THE KMS_Module SHALL enable automatic key rotation for the KMS_Key.
6. THE KMS_Module SHALL accept a `deletion_window_in_days` variable with a default value of 30.

### Requirement 2: KMS Encryption of Cognito Client Secret

**User Story:** As a platform engineer, I want the Cognito client secret encrypted with KMS at the Terraform layer, so that the plaintext secret is not stored in state outputs or passed to downstream consumers unprotected.

#### Acceptance Criteria

1. WHEN the Cognito_Module produces a client secret, THE Environment_Config SHALL encrypt the client secret using the KMS_Key via an `aws_kms_ciphertext` data source or resource.
2. THE Environment_Config SHALL output the Client_Secret_Ciphertext as a non-sensitive base64-encoded string.
3. THE Environment_Config SHALL pass the Client_Secret_Ciphertext (not the plaintext secret) to any Lambda environment variables that require the client secret.
4. THE Environment_Config SHALL pass the KMS_Key ARN to modules that need to decrypt the Client_Secret_Ciphertext.

### Requirement 3: IAM Permissions for KMS Decrypt

**User Story:** As a platform engineer, I want the Lambda execution roles to have KMS decrypt permissions, so that Lambdas can decrypt the encrypted client secret at runtime without manual credential management.

#### Acceptance Criteria

1. THE IAM_Authorizer_Module SHALL accept an optional `kms_key_arn` variable.
2. WHEN `kms_key_arn` is provided, THE IAM_Authorizer_Module SHALL attach an inline policy granting `kms:Decrypt` on the specified KMS_Key to the authorizer Lambda role.
3. THE IAM_Lambda_Module SHALL accept an optional `kms_key_arn` variable.
4. WHEN `kms_key_arn` is provided, THE IAM_Lambda_Module SHALL attach an inline policy granting `kms:Decrypt` on the specified KMS_Key to the backend Lambda role.
5. THE inline KMS decrypt policies SHALL restrict the `Resource` to the specific KMS_Key ARN (not `*`).

### Requirement 4: Authorizer Lambda KMS Decryption Support

**User Story:** As a platform engineer, I want the authorizer Lambda to decrypt KMS-encrypted values at runtime, so that sensitive credentials are only available in memory during execution and never stored in plaintext in environment variables.

#### Acceptance Criteria

1. WHEN the Authorizer_Lambda receives a KMS-encrypted environment variable, THE Authorizer_Lambda SHALL decrypt the value using the AWS KMS Decrypt API via boto3.
2. THE Authorizer_Lambda SHALL cache the decrypted value in memory for the lifetime of the Lambda execution context to avoid repeated KMS API calls.
3. IF the KMS Decrypt API call fails, THEN THE Authorizer_Lambda SHALL log the error and raise an exception that results in a Deny policy.
4. THE Authorizer_Lambda SHALL import boto3 only when KMS decryption is needed (lazy import) to minimize cold-start impact when no encrypted variables are configured.

### Requirement 5: Cognito M2M Token URL Output

**User Story:** As a platform engineer, I want the Cognito module to output a clearly named M2M token URL, so that consuming services and CI/CD pipelines can programmatically obtain access tokens using the `client_credentials` grant without hardcoding any endpoint.

#### Acceptance Criteria

1. THE Cognito_Module SHALL output a value named `m2m_token_url` containing the full OAuth2 token endpoint URL constructed from the Cognito domain.
2. THE Cognito_Module SHALL retain the existing `token_endpoint` output for backward compatibility.
3. THE Environment_Config SHALL output the `m2m_token_url` so that callers can retrieve the token endpoint from Terraform outputs.
4. THE `m2m_token_url` output description SHALL specify that the endpoint is used with the `client_credentials` grant type.

### Requirement 6: Encrypted Credentials Passed as Lambda Environment Variables

**User Story:** As a platform engineer, I want encrypted credentials passed to Lambda functions via environment variables, so that no plaintext secrets appear in Terraform state, outputs, or the Lambda console.

#### Acceptance Criteria

1. THE Authorizer_Lambda Terraform resource SHALL receive the Client_Secret_Ciphertext as an environment variable named `ENCRYPTED_CLIENT_SECRET`.
2. THE Authorizer_Lambda Terraform resource SHALL receive the KMS_Key ARN as an environment variable named `KMS_KEY_ARN`.
3. THE Authorizer_Lambda Terraform resource SHALL receive the M2M_Token_URL as an environment variable named `M2M_TOKEN_URL`.
4. WHEN the Authorizer_Lambda does not require the client secret for its JWT validation flow, THE Authorizer_Lambda SHALL still accept the encrypted environment variables for future use by downstream consumers or token refresh logic.

### Requirement 7: No Hardcoded Credentials

**User Story:** As a security engineer, I want to ensure no credentials are hardcoded anywhere in the infrastructure code or Lambda handlers, so that the system follows security best practices and credentials are managed exclusively through AWS services.

#### Acceptance Criteria

1. THE Authorizer_Lambda handler source code SHALL contain zero hardcoded AWS credentials, client secrets, or token endpoint URLs.
2. THE Terraform modules SHALL not contain hardcoded secrets, access keys, or passwords in any `.tf` file.
3. THE Environment_Config SHALL derive all credential values from Terraform module outputs or AWS service integrations (Cognito, KMS).
4. WHEN a consuming service needs the client secret, THE consuming service SHALL decrypt the Client_Secret_Ciphertext at runtime using the KMS Decrypt API.
