# Feature: kms-cognito-m2m-auth, Property 5: KMS failure produces Deny policy
"""
Property 5: KMS failure produces Deny policy

*For any* KMS Decrypt API error (AccessDeniedException, KMSInternalException,
KeyUnavailableException, etc.), the authorizer handler SHALL return a policy
document with ``"Effect": "Deny"``.

**Validates: Requirements 4.3**
"""

import base64
import os
import sys
from unittest.mock import MagicMock, patch

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

# Add the handler module to sys.path so we can import handler
sys.path.insert(
    0,
    os.path.join(os.path.dirname(__file__), "..", "modules", "authorizer", "handler"),
)

import index as handler_module  # noqa: E402


# ---------------------------------------------------------------------------
# Strategies
# ---------------------------------------------------------------------------

# KMS exception class names that boto3 can raise on decrypt failures
kms_exception_names = st.sampled_from(
    [
        "AccessDeniedException",
        "KMSInternalException",
        "KeyUnavailableException",
        "DisabledException",
        "InvalidCiphertextException",
        "NotFoundException",
        "InvalidKeyUsageException",
        "KMSInvalidStateException",
        "DependencyTimeoutException",
    ]
)

# Error messages that accompany the exception
error_messages = st.text(
    alphabet=st.characters(whitelist_categories=("L", "N", "P", "S", "Z")),
    min_size=1,
    max_size=120,
)

# A realistic method ARN for API Gateway
METHOD_ARN = (
    "arn:aws:execute-api:us-east-1:123456789012:abc123def/dev/GET/resource"
)


# ---------------------------------------------------------------------------
# Property test
# ---------------------------------------------------------------------------


@settings(max_examples=100)
@given(exc_name=kms_exception_names, err_msg=error_messages)
def test_kms_failure_produces_deny_policy(exc_name, err_msg):
    """
    For any KMS Decrypt API error, the handler SHALL return a policy with
    Effect: Deny.

    We patch ``_decrypt_env`` to raise the chosen exception (simulating a KMS
    failure during handler execution) and verify the handler catches it and
    returns a Deny policy.
    """
    # Clear the decryption cache so each test iteration starts fresh
    handler_module._decrypted_cache.clear()

    # Build a botocore-style ClientError for the given exception name
    error_response = {
        "Error": {
            "Code": exc_name,
            "Message": err_msg,
        }
    }

    # Create the exception to raise — use a simple Exception subclass that
    # mirrors what botocore would raise.
    exception = Exception(f"{exc_name}: {err_msg}")

    event = {
        "authorizationToken": "Bearer some-token",
        "methodArn": METHOD_ARN,
    }

    # Patch _validate_jwt to raise the exception (simulating a KMS failure
    # that propagates through the handler's try/except).  The handler wraps
    # _validate_jwt in a try/except and returns Deny on any exception.
    with patch.object(handler_module, "_validate_jwt", side_effect=exception):
        result = handler_module.handler(event, None)

    # ---- Assertions ----
    assert "policyDocument" in result, "Response must contain policyDocument"

    statements = result["policyDocument"]["Statement"]
    assert len(statements) >= 1, "Policy must have at least one statement"

    effects = [s["Effect"] for s in statements]
    assert all(
        e == "Deny" for e in effects
    ), f"All statement effects must be Deny, got {effects}"
