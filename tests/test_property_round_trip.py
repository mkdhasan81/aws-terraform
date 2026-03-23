# Feature: kms-cognito-m2m-auth, Property 3: Encrypt-then-decrypt round trip
"""
Property 3: Encrypt-then-decrypt round trip

*For any* plaintext string, encrypting it with the KMS key and then decrypting
the resulting ciphertext via ``_decrypt_env`` SHALL return the original plaintext
string.

**Validates: Requirements 2.1, 4.1, 7.4**
"""

import base64
import os
import sys
from unittest.mock import MagicMock, patch

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

# Add the handler module to sys.path so we can import _decrypt_env
sys.path.insert(
    0,
    os.path.join(os.path.dirname(__file__), "..", "modules", "authorizer", "handler"),
)

import index as handler_module  # noqa: E402


# ---------------------------------------------------------------------------
# Strategies
# ---------------------------------------------------------------------------

# Environment variable names (uppercase letters, digits, underscores)
env_var_names = st.from_regex(r"[A-Z][A-Z_0-9]{0,30}", fullmatch=True)

# Plaintext values — non-empty printable strings (the kind of value you'd
# encrypt with KMS, e.g. a client secret or token URL)
plaintext_values = st.text(
    alphabet=st.characters(whitelist_categories=("L", "N", "P", "S")),
    min_size=1,
    max_size=200,
)


# ---------------------------------------------------------------------------
# Property test
# ---------------------------------------------------------------------------


@settings(max_examples=100)
@given(env_name=env_var_names, plaintext=plaintext_values)
def test_encrypt_then_decrypt_round_trip(env_name, plaintext):
    """
    For any plaintext string, simulating the encrypt step (base64-encoding the
    plaintext, as ``aws_kms_ciphertext`` would produce) and then calling
    ``_decrypt_env`` (which base64-decodes and calls KMS decrypt) SHALL return
    the original plaintext.

    The mock KMS decrypt returns the original plaintext bytes, simulating the
    inverse of the encrypt operation.
    """
    # Clear the cache so each test iteration starts fresh
    handler_module._decrypted_cache.clear()

    # --- Simulate the "encrypt" step ---
    # In the real system, Terraform's aws_kms_ciphertext encrypts the plaintext
    # and stores the base64-encoded ciphertext as an env var.  We simulate this
    # by base64-encoding the plaintext bytes.
    plaintext_bytes = plaintext.encode("utf-8")
    fake_ciphertext_b64 = base64.b64encode(plaintext_bytes).decode("utf-8")

    # --- Mock KMS decrypt as the inverse operation ---
    mock_kms_client = MagicMock()
    mock_kms_client.decrypt.return_value = {
        "Plaintext": plaintext_bytes,
    }

    mock_boto3 = MagicMock()
    mock_boto3.client.return_value = mock_kms_client

    # --- Set the env var and call _decrypt_env ---
    with patch.dict(os.environ, {env_name: fake_ciphertext_b64}):
        with patch.dict("sys.modules", {"boto3": mock_boto3}):
            result = handler_module._decrypt_env(env_name)

    # --- Assert round trip: decrypt(encrypt(plaintext)) == plaintext ---
    assert result == plaintext, (
        f"Round trip failed: expected {plaintext!r}, got {result!r}"
    )

    # Verify KMS decrypt was called with the correct ciphertext blob
    mock_kms_client.decrypt.assert_called_once_with(
        CiphertextBlob=plaintext_bytes,
    )
