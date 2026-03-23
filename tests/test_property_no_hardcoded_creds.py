# Feature: kms-cognito-m2m-auth, Property 7: No hardcoded credentials in source files
"""
Property 7: No hardcoded credentials in source files

*For any* source file (``.py`` or ``.tf``) in the repository, the file content
SHALL not match patterns for hardcoded AWS access keys (``AKIA[0-9A-Z]{16}``),
secret keys (40-char base64 strings assigned to credential-named variables),
plaintext client secrets, or hardcoded ``amazoncognito.com`` token URLs in
Lambda handler code.

**Validates: Requirements 7.1, 7.2**
"""

import os
import re

import pytest
from hypothesis import given, settings, assume
from hypothesis import strategies as st

# ---------------------------------------------------------------------------
# Repository paths to scan
# ---------------------------------------------------------------------------

REPO_ROOT = os.path.join(os.path.dirname(__file__), "..")
SCAN_DIRS = ["modules", "environments"]
EXCLUDE_DIRS = {"tests", ".git", "__pycache__", ".terraform", ".hypothesis"}

# ---------------------------------------------------------------------------
# Credential patterns
# ---------------------------------------------------------------------------

# 1. AWS access key pattern: AKIA followed by exactly 16 uppercase alphanumeric chars
AWS_ACCESS_KEY_RE = re.compile(r"AKIA[0-9A-Z]{16}")

# 2. Secret key pattern: 40-char base64 string assigned to credential-named variables
#    Matches lines like: secret = "aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789+/==" (40 chars)
SECRET_KEY_RE = re.compile(
    r"""(?i)(?:secret|password|credential|access_key)\s*=\s*["'][A-Za-z0-9+/=]{40}["']"""
)

# 3. Hardcoded amazoncognito.com URLs in Python files (not in Terraform interpolation)
#    Matches literal URLs like https://foo.auth.us-east-1.amazoncognito.com
#    but NOT Terraform interpolation expressions like ${...}.amazoncognito.com
HARDCODED_COGNITO_URL_RE = re.compile(
    r'https://[a-zA-Z0-9\-]+\.auth\.[a-z]{2}-[a-z]+-[0-9]\.amazoncognito\.com'
)

# ---------------------------------------------------------------------------
# File discovery
# ---------------------------------------------------------------------------


def discover_source_files() -> list[str]:
    """Discover all .py and .tf files under SCAN_DIRS, excluding EXCLUDE_DIRS."""
    source_files = []
    for scan_dir in SCAN_DIRS:
        root_path = os.path.join(REPO_ROOT, scan_dir)
        if not os.path.isdir(root_path):
            continue
        for dirpath, dirnames, filenames in os.walk(root_path):
            # Prune excluded directories
            dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIRS]
            for filename in filenames:
                if filename.endswith(".py") or filename.endswith(".tf"):
                    source_files.append(os.path.join(dirpath, filename))
    return source_files


# Cache discovered files so hypothesis doesn't re-scan on every example
_SOURCE_FILES = discover_source_files()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def scan_file_for_credentials(filepath: str) -> list[str]:
    """Scan a single file for hardcoded credential patterns. Returns list of violations."""
    with open(filepath, "r", errors="replace") as f:
        content = f.read()

    violations = []

    # Check for AWS access keys
    matches = AWS_ACCESS_KEY_RE.findall(content)
    if matches:
        violations.append(f"AWS access key pattern found: {matches}")

    # Check for secret key assignments
    matches = SECRET_KEY_RE.findall(content)
    if matches:
        violations.append(f"Hardcoded secret key assignment found: {matches}")

    # Check for hardcoded amazoncognito.com URLs in Python files only
    # (Terraform files use interpolation expressions which are fine)
    if filepath.endswith(".py"):
        for line in content.splitlines():
            if HARDCODED_COGNITO_URL_RE.search(line):
                violations.append(
                    f"Hardcoded amazoncognito.com URL in Python file: {line.strip()}"
                )

    return violations


# ---------------------------------------------------------------------------
# Strategies
# ---------------------------------------------------------------------------

# Strategy that samples from the discovered source files
source_file_strategy = st.sampled_from(_SOURCE_FILES) if _SOURCE_FILES else st.nothing()

# ---------------------------------------------------------------------------
# Structural check — confirm we found files to scan
# ---------------------------------------------------------------------------


def test_source_files_discovered():
    """Ensure we discovered at least one .py or .tf file to scan."""
    assert len(_SOURCE_FILES) > 0, (
        f"No .py or .tf files found under {SCAN_DIRS}. "
        "Cannot validate no-hardcoded-credentials property."
    )


def test_discovered_files_include_py_and_tf():
    """Ensure we have both .py and .tf files in the scan set."""
    extensions = {os.path.splitext(f)[1] for f in _SOURCE_FILES}
    assert ".py" in extensions, "No .py files found in scan directories"
    assert ".tf" in extensions, "No .tf files found in scan directories"


# ---------------------------------------------------------------------------
# Property test
# ---------------------------------------------------------------------------


@settings(max_examples=100)
@given(filepath=source_file_strategy)
def test_no_hardcoded_credentials(filepath):
    """
    For any source file (.py or .tf) in the repository (under modules/ and
    environments/), the file content SHALL not match patterns for:
    1. AWS access key pattern: AKIA[0-9A-Z]{16}
    2. Secret key pattern: 40-char base64 strings assigned to credential-named variables
    3. Hardcoded amazoncognito.com URLs in Python files (not in Terraform interpolation)

    **Validates: Requirements 7.1, 7.2**
    """
    assume(os.path.isfile(filepath))

    violations = scan_file_for_credentials(filepath)

    assert not violations, (
        f"Hardcoded credentials found in {os.path.relpath(filepath, REPO_ROOT)}:\n"
        + "\n".join(f"  - {v}" for v in violations)
    )
