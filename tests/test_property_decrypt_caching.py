# Feature: kms-cognito-m2m-auth, Property 4: Decrypt result caching
"""
Property 4: Decrypt result caching

*For any* sequence of N calls (N >= 2) to `_decrypt_env` with the same
environment variable name, the KMS Decrypt API SHALL be invoked exactly once,
and all N calls SHALL return the same plaintext value.

**Validates: Requirements 4.2**
"""

import base64
import os
import sys
from unittest.mock import MagicMock, patch

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

# Add the handler module to sys.path so we can import _decrypt_env
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "modules", "authorizer", "handler"))

import index as handler_module  # noqa: E402


# Strategy: env var names that are valid (uppercase letters/underscores, non-empty)
env_var_names = st.from_regex(r"[A-Z][A-Z_0-9]{0,30}", fullmatch=True)

# Strategy: plaintext values (non-empty printable strings)
plaintext_values = st.text(
    alphabet=st.characters(whitelist_categories=("L", "N", "P", "S")),
    min_size=1,
    max_size=100,
)

# Strategy: call counts (N >= 2)
call_counts = st.integers(min_value=2, max_value=10)


@settings(max_examples=100)
@given(env_name=env_var_names, plaintext=plaintext_values, n_calls=call_counts)
def test_decrypt_caching_calls_kms_once(env_name, plaintext, n_calls):
    """
    For any env var name and N >= 2 calls, KMS Decrypt is invoked exactly once
    and all calls return the same plaintext.
    """
    # Clear the cache before each test case
    handler_module._decrypted_cache.clear()

    # Prepare a fake ciphertext (base64-encoded bytes)
    fake_ciphertext = base64.b64encode(b"encrypted-" + plaintext.encode("utf-8")).decode("utf-8")

    # Mock KMS client that returns the plaintext
    mock_kms_client = MagicMock()
    mock_kms_client.decrypt.return_value = {
        "Plaintext": plaintext.encode("utf-8"),
    }

    mock_boto3 = MagicMock()
    mock_boto3.client.return_value = mock_kms_client

    with patch.dict(os.environ, {env_name: fake_ciphertext}):
        with patch.dict("sys.modules", {"boto3": mock_boto3}):
            results = []
            for _ in range(n_calls):
                result = handler_module._decrypt_env(env_name)
                results.append(result)

    # Assert: KMS decrypt was called exactly once
    assert mock_kms_client.decrypt.call_count == 1, (
        f"Expected KMS decrypt to be called exactly 1 time, "
        f"but was called {mock_kms_client.decrypt.call_count} times "
        f"for {n_calls} calls to _decrypt_env"
    )

    # Assert: all N calls returned the same plaintext value
    assert all(r == plaintext for r in results), (
        f"Expected all {n_calls} calls to return {plaintext!r}, "
        f"but got {results!r}"
    )
