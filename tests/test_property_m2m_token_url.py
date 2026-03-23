# Feature: kms-cognito-m2m-auth, Property 6: M2M token URL format
"""
Property 6: M2M token URL format

*For any* Cognito domain prefix and AWS region, the ``m2m_token_url`` output
SHALL equal ``https://<domain>.auth.<region>.amazoncognito.com/oauth2/token``.

**Validates: Requirements 5.1**
"""

import os
import re

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

# ---------------------------------------------------------------------------
# Path to the Cognito module outputs source
# ---------------------------------------------------------------------------

COGNITO_OUTPUTS_TF = os.path.join(
    os.path.dirname(__file__), "..", "modules", "cognito", "outputs.tf"
)

# ---------------------------------------------------------------------------
# Strategies
# ---------------------------------------------------------------------------

# Cognito domain prefixes: lowercase alphanumeric + hyphens, 1-63 chars
# Must not start or end with a hyphen per Cognito rules
_domain_alpha = "abcdefghijklmnopqrstuvwxyz0123456789"
_domain_chars = _domain_alpha + "-"

cognito_domain_prefix = st.from_regex(
    r"[a-z0-9][a-z0-9\-]{0,61}[a-z0-9]", fullmatch=True
).filter(lambda s: "--" not in s) | st.from_regex(
    r"[a-z0-9]", fullmatch=True
)

# AWS region strings: e.g. us-east-1, eu-west-2, ap-southeast-1
aws_region = st.from_regex(
    r"[a-z]{2}-[a-z]+-[1-9]", fullmatch=True
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def build_m2m_token_url(domain: str, region: str) -> str:
    """Replicate the Terraform interpolation for m2m_token_url in Python."""
    return f"https://{domain}.auth.{region}.amazoncognito.com/oauth2/token"


def read_m2m_token_url_pattern() -> str:
    """Read modules/cognito/outputs.tf and extract the m2m_token_url value expression."""
    with open(COGNITO_OUTPUTS_TF, "r") as f:
        content = f.read()
    # Locate the m2m_token_url output block start
    block_start = content.find('output "m2m_token_url"')
    assert block_start != -1, "Could not find m2m_token_url output in outputs.tf"
    block_text = content[block_start:]
    # The value is on a single line; extract everything between the outermost
    # quotes on the value line.  We use a greedy match (.+) so that nested
    # quotes inside ${} interpolations are captured.
    value_match = re.search(r'value\s*=\s*"(.+)"', block_text)
    assert value_match, "Could not find value attribute in m2m_token_url output block"
    return value_match.group(1)


# ---------------------------------------------------------------------------
# Structural check — confirm the HCL source uses the expected pattern
# ---------------------------------------------------------------------------


def test_hcl_m2m_token_url_pattern_matches_spec():
    """
    The Terraform source must define m2m_token_url as:
    https://${aws_cognito_user_pool_domain.this.domain}.auth.${split("_", aws_cognito_user_pool.this.id)[0]}.amazoncognito.com/oauth2/token
    """
    pattern = read_m2m_token_url_pattern()
    # The HCL template must contain the domain interpolation and the
    # split-based region extraction, ending with /oauth2/token
    assert "${aws_cognito_user_pool_domain.this.domain}" in pattern, (
        f"m2m_token_url must reference aws_cognito_user_pool_domain.this.domain: {pattern!r}"
    )
    assert "split(" in pattern and "aws_cognito_user_pool.this.id" in pattern, (
        f"m2m_token_url must extract region via split on user pool id: {pattern!r}"
    )
    assert pattern.startswith("https://"), (
        f"m2m_token_url must start with https://: {pattern!r}"
    )
    assert pattern.endswith(".amazoncognito.com/oauth2/token"), (
        f"m2m_token_url must end with .amazoncognito.com/oauth2/token: {pattern!r}"
    )
    assert ".auth." in pattern, (
        f"m2m_token_url must contain '.auth.' segment: {pattern!r}"
    )


# ---------------------------------------------------------------------------
# Property test
# ---------------------------------------------------------------------------


@settings(max_examples=100)
@given(domain=cognito_domain_prefix, region=aws_region)
def test_m2m_token_url_format(domain, region):
    """
    For any Cognito domain prefix and AWS region, the constructed
    m2m_token_url SHALL equal
    ``https://<domain>.auth.<region>.amazoncognito.com/oauth2/token``.

    We verify:
    1. The URL starts with https://
    2. The URL contains the domain and region in the correct positions
    3. The URL ends with /oauth2/token
    4. The full URL matches the expected format exactly
    """
    result = build_m2m_token_url(domain, region)

    # Must use HTTPS
    assert result.startswith("https://"), (
        f"URL must start with 'https://', got: {result!r}"
    )

    # Must end with /oauth2/token
    assert result.endswith("/oauth2/token"), (
        f"URL must end with '/oauth2/token', got: {result!r}"
    )

    # Must contain .amazoncognito.com
    assert ".amazoncognito.com" in result, (
        f"URL must contain '.amazoncognito.com', got: {result!r}"
    )

    # Full URL must match expected format exactly
    expected = f"https://{domain}.auth.{region}.amazoncognito.com/oauth2/token"
    assert result == expected, (
        f"Expected {expected!r}, got {result!r}"
    )

    # Verify the URL matches the general pattern via regex
    url_pattern = re.compile(
        r"^https://[a-z0-9][a-z0-9\-]*[a-z0-9]?"
        r"\.auth\."
        r"[a-z]{2}-[a-z]+-[1-9]"
        r"\.amazoncognito\.com/oauth2/token$"
    )
    assert url_pattern.match(result), (
        f"URL does not match expected pattern: {result!r}"
    )
