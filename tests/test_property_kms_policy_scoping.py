# Feature: kms-cognito-m2m-auth, Property 2: Conditional KMS Decrypt policy is scoped to exact key ARN
"""
Property 2: Conditional KMS Decrypt policy is scoped to exact key ARN

*For any* IAM module (authorizer or lambda) with a non-empty ``kms_key_arn``
input, the generated inline policy document SHALL contain
``"Action": "kms:Decrypt"`` with ``"Resource"`` set to exactly that
``kms_key_arn`` value (never ``"*"``), and when ``kms_key_arn`` is empty,
no such policy SHALL be created.

**Validates: Requirements 3.2, 3.4, 3.5**
"""

import json
import os
import re
from typing import Dict, Optional

import pytest
from hypothesis import given, settings, assume
from hypothesis import strategies as st

# ---------------------------------------------------------------------------
# Paths to the IAM module sources
# ---------------------------------------------------------------------------

_REPO_ROOT = os.path.join(os.path.dirname(__file__), "..")

IAM_MODULE_PATHS = {
    "authorizer": os.path.join(_REPO_ROOT, "modules", "iam", "authorizer", "main.tf"),
    "lambda": os.path.join(_REPO_ROOT, "modules", "iam", "lambda", "main.tf"),
}

# ---------------------------------------------------------------------------
# Strategies
# ---------------------------------------------------------------------------

# Generate realistic KMS key ARN strings
kms_key_arn_strategy = st.from_regex(
    r"arn:aws:kms:us-east-1:[0-9]{12}:key/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
    fullmatch=True,
)

# ---------------------------------------------------------------------------
# HCL parsing helpers
# ---------------------------------------------------------------------------


def _read_file(path: str) -> str:
    with open(path, "r") as f:
        return f.read()


def _extract_kms_decrypt_block(content: str) -> Optional[str]:
    """Extract the full aws_iam_role_policy.kms_decrypt resource block."""
    pattern = (
        r'resource\s+"aws_iam_role_policy"\s+"kms_decrypt"\s*\{'
    )
    match = re.search(pattern, content)
    if not match:
        return None

    # Find the matching closing brace by counting braces
    start = match.start()
    brace_count = 0
    for i in range(match.start(), len(content)):
        if content[i] == "{":
            brace_count += 1
        elif content[i] == "}":
            brace_count -= 1
            if brace_count == 0:
                return content[start : i + 1]
    return None


def _extract_count_expression(block: str) -> Optional[str]:
    """Extract the count expression from a resource block."""
    match = re.search(r'count\s*=\s*(.+)', block)
    if match:
        return match.group(1).strip()
    return None


def _extract_policy_json_template(block: str) -> Optional[str]:
    """Extract the jsonencode(...) argument from the policy attribute."""
    match = re.search(r'policy\s*=\s*jsonencode\((\{.*?\})\s*\)', block, re.DOTALL)
    if match:
        return match.group(1)
    return None


def _extract_resource_value(policy_template: str) -> Optional[str]:
    """Extract the Resource value from the HCL policy template."""
    match = re.search(r'Resource\s*=\s*(\S+)', policy_template)
    if match:
        return match.group(1).strip()
    return None


def _extract_action_value(policy_template: str) -> Optional[str]:
    """Extract the Action value from the HCL policy template."""
    match = re.search(r'Action\s*=\s*"([^"]+)"', policy_template)
    if match:
        return match.group(1)
    return None


# ---------------------------------------------------------------------------
# Structural verification — run once per module
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("module_name,module_path", IAM_MODULE_PATHS.items())
class TestKmsDecryptPolicyStructure:
    """Structural checks on the HCL source for both IAM modules."""

    def test_kms_decrypt_block_exists(self, module_name, module_path):
        content = _read_file(module_path)
        block = _extract_kms_decrypt_block(content)
        assert block is not None, (
            f"modules/iam/{module_name}/main.tf must contain "
            f"aws_iam_role_policy.kms_decrypt resource"
        )

    def test_conditional_creation_on_enable_kms_decrypt(self, module_name, module_path):
        content = _read_file(module_path)
        block = _extract_kms_decrypt_block(content)
        assert block is not None
        count_expr = _extract_count_expression(block)
        assert count_expr is not None, (
            f"kms_decrypt resource in {module_name} must have a count expression"
        )
        assert "var.enable_kms_decrypt" in count_expr, (
            f"count must check var.enable_kms_decrypt, got: {count_expr!r}"
        )
        assert "? 1 : 0" in count_expr, (
            f"count must use ternary ? 1 : 0, got: {count_expr!r}"
        )

    def test_action_is_kms_decrypt(self, module_name, module_path):
        content = _read_file(module_path)
        block = _extract_kms_decrypt_block(content)
        assert block is not None
        policy_template = _extract_policy_json_template(block)
        assert policy_template is not None, (
            f"kms_decrypt resource in {module_name} must have a jsonencode policy"
        )
        action = _extract_action_value(policy_template)
        assert action == "kms:Decrypt", (
            f"Action must be 'kms:Decrypt', got: {action!r}"
        )

    def test_resource_is_var_kms_key_arn(self, module_name, module_path):
        content = _read_file(module_path)
        block = _extract_kms_decrypt_block(content)
        assert block is not None
        policy_template = _extract_policy_json_template(block)
        assert policy_template is not None
        resource = _extract_resource_value(policy_template)
        assert resource == "var.kms_key_arn", (
            f"Resource must be var.kms_key_arn (not '*'), got: {resource!r}"
        )

    def test_resource_is_never_wildcard(self, module_name, module_path):
        content = _read_file(module_path)
        block = _extract_kms_decrypt_block(content)
        assert block is not None
        policy_template = _extract_policy_json_template(block)
        assert policy_template is not None
        resource = _extract_resource_value(policy_template)
        assert resource != '"*"', (
            f"Resource must NEVER be '*' in {module_name}"
        )


# ---------------------------------------------------------------------------
# Property-based tests
# ---------------------------------------------------------------------------


def _hcl_object_to_json(hcl: str) -> str:
    """
    Convert a simple HCL object literal (as used inside jsonencode()) to
    valid JSON.  Handles:
      - ``key = value``  →  ``"key": value``
      - Missing commas between key-value pairs
      - Unquoted identifiers used as variable references are already
        substituted before this function is called.
    """
    # Replace HCL-style `key = ` with `"key": `
    result = re.sub(r'(\w+)\s*=\s*', r'"\1": ', hcl)

    # Add commas between adjacent JSON values on separate lines.
    # Match a line ending with a value (string, number, ], }) that is
    # followed by another key-value pair or closing bracket on the next line.
    result = re.sub(
        r'("(?:[^"\\]|\\.)*"|\d+|true|false|null|\]|\})\s*\n(\s*")',
        r'\1,\n\2',
        result,
    )

    return result


def _simulate_policy_for_arn(module_path: str, kms_key_arn: str, enable_kms_decrypt: bool = True) -> Optional[dict]:
    """
    Simulate what Terraform would produce for a given kms_key_arn value.

    Reads the HCL source, extracts the jsonencode template, substitutes
    var.kms_key_arn with the provided value, and returns the resulting
    policy dict. Returns None if count would evaluate to 0.
    """
    content = _read_file(module_path)
    block = _extract_kms_decrypt_block(content)
    if block is None:
        return None

    # Evaluate count condition based on enable_kms_decrypt boolean
    count_expr = _extract_count_expression(block)
    if count_expr and "var.enable_kms_decrypt" in count_expr:
        if not enable_kms_decrypt:
            return None  # count = 0, resource not created

    # Extract and simulate the policy
    policy_template = _extract_policy_json_template(block)
    if policy_template is None:
        return None

    # Substitute var.kms_key_arn with the actual value
    simulated = policy_template.replace("var.kms_key_arn", f'"{kms_key_arn}"')
    # Convert HCL object syntax to valid JSON
    simulated = _hcl_object_to_json(simulated)

    try:
        return json.loads(simulated)
    except json.JSONDecodeError:
        pytest.fail(f"Failed to parse simulated policy JSON:\n{simulated}")


@settings(max_examples=100)
@given(kms_key_arn=kms_key_arn_strategy)
def test_policy_resource_matches_exact_arn(kms_key_arn: str):
    """
    **Validates: Requirements 3.2, 3.4, 3.5**

    For any random KMS key ARN, the simulated policy document in both IAM
    modules SHALL have Resource set to exactly that ARN (never '*').
    """
    for module_name, module_path in IAM_MODULE_PATHS.items():
        policy = _simulate_policy_for_arn(module_path, kms_key_arn)
        assert policy is not None, (
            f"Policy must be created for non-empty ARN in {module_name}"
        )

        statements = policy.get("Statement", [])
        assert len(statements) == 1, (
            f"Expected exactly 1 statement in {module_name}, got {len(statements)}"
        )

        stmt = statements[0]
        assert stmt["Action"] == "kms:Decrypt", (
            f"Action must be 'kms:Decrypt' in {module_name}, got: {stmt['Action']!r}"
        )
        assert stmt["Resource"] == kms_key_arn, (
            f"Resource in {module_name} must be the exact ARN {kms_key_arn!r}, "
            f"got: {stmt['Resource']!r}"
        )
        assert stmt["Resource"] != "*", (
            f"Resource in {module_name} must never be '*'"
        )


@settings(max_examples=100)
@given(data=st.data())
def test_disabled_kms_produces_no_policy(data):
    """
    **Validates: Requirements 3.2, 3.4, 3.5**

    When enable_kms_decrypt is false, the count evaluates to 0 and no policy
    resource is created in either IAM module.
    """
    for module_name, module_path in IAM_MODULE_PATHS.items():
        policy = _simulate_policy_for_arn(module_path, "", enable_kms_decrypt=False)
        assert policy is None, (
            f"No policy should be created when enable_kms_decrypt is false in {module_name}"
        )
