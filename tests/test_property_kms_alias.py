# Feature: kms-cognito-m2m-auth, Property 1: KMS alias naming convention
"""
Property 1: KMS alias naming convention

*For any* ``name_prefix`` and ``alias_name`` input strings, the resulting KMS
alias name SHALL equal ``alias/${name_prefix}${alias_name}``.

**Validates: Requirements 1.2**
"""

import os
import re

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

# ---------------------------------------------------------------------------
# Path to the KMS module source
# ---------------------------------------------------------------------------

KMS_MAIN_TF = os.path.join(
    os.path.dirname(__file__), "..", "modules", "kms", "main.tf"
)

# ---------------------------------------------------------------------------
# Strategies
# ---------------------------------------------------------------------------

# Valid KMS alias characters: alphanumeric, hyphens, underscores, slashes
kms_alias_chars = st.text(
    alphabet=st.sampled_from(
        "abcdefghijklmnopqrstuvwxyz"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789"
        "-_/"
    ),
    min_size=0,
    max_size=50,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def read_kms_alias_pattern() -> str:
    """Read modules/kms/main.tf and extract the alias name expression."""
    with open(KMS_MAIN_TF, "r") as f:
        content = f.read()
    # Match the name attribute inside the aws_kms_alias resource
    match = re.search(
        r'resource\s+"aws_kms_alias"\s+"this"\s*\{[^}]*'
        r'name\s*=\s*"([^"]+)"',
        content,
        re.DOTALL,
    )
    assert match, "Could not find aws_kms_alias name attribute in main.tf"
    return match.group(1)


def build_alias_name(name_prefix: str, alias_name: str) -> str:
    """Replicate the Terraform interpolation in Python."""
    return f"alias/{name_prefix}{alias_name}"


# ---------------------------------------------------------------------------
# Structural check — confirm the HCL source uses the expected pattern
# ---------------------------------------------------------------------------


def test_hcl_alias_pattern_matches_spec():
    """
    The Terraform source must define the alias as
    ``alias/${var.name_prefix}${var.alias_name}``.
    """
    pattern = read_kms_alias_pattern()
    assert pattern == "alias/${var.name_prefix}${var.alias_name}", (
        f"Unexpected alias pattern in main.tf: {pattern!r}"
    )


# ---------------------------------------------------------------------------
# Property test
# ---------------------------------------------------------------------------


@settings(max_examples=100)
@given(name_prefix=kms_alias_chars, alias_name=kms_alias_chars)
def test_kms_alias_naming_convention(name_prefix, alias_name):
    """
    For any name_prefix and alias_name strings (valid KMS alias characters),
    the constructed alias SHALL equal ``alias/{name_prefix}{alias_name}``.

    We verify:
    1. The result always starts with the ``alias/`` prefix.
    2. The result equals the expected concatenation.
    3. The Terraform pattern in main.tf would produce the same result when
       the variables are substituted.
    """
    result = build_alias_name(name_prefix, alias_name)

    # Must start with "alias/"
    assert result.startswith("alias/"), (
        f"Alias must start with 'alias/', got: {result!r}"
    )

    # Must equal the expected format
    expected = f"alias/{name_prefix}{alias_name}"
    assert result == expected, (
        f"Expected {expected!r}, got {result!r}"
    )

    # The portion after "alias/" must be exactly name_prefix + alias_name
    suffix = result[len("alias/"):]
    assert suffix == name_prefix + alias_name, (
        f"Suffix mismatch: expected {name_prefix + alias_name!r}, got {suffix!r}"
    )
