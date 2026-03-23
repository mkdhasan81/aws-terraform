"""
Lambda Authorizer — Cognito JWT validation
Validates a Cognito-issued JWT from the Authorization header.

Environment variables (set via Terraform):
  JWKS_URI       — Cognito JWKS endpoint
  ISSUER         — Cognito issuer URL
  REQUIRED_SCOPE — OAuth2 scope required to access the API (e.g. "https://api/read")

Flow:
  1. Extract Bearer token from Authorization header
  2. Decode JWT header to get kid (key ID)
  3. Fetch JWKS from Cognito and find matching public key
  4. Verify JWT signature, expiry, issuer, and scope
  5. Return Allow or Deny IAM policy
"""

import json
import os
import time
import urllib.request
import urllib.error
from base64 import urlsafe_b64decode

# Simple in-memory JWKS cache — avoids fetching on every request
_jwks_cache: dict = {}
_jwks_cache_ttl: float = 0.0
_CACHE_SECONDS = 3600  # refresh JWKS every hour


def handler(event, context):
    token = event.get("authorizationToken", "")
    method_arn = event.get("methodArn", "")

    if token.lower().startswith("bearer "):
        token = token[7:]

    try:
        _validate_jwt(token)
        return _policy("Allow", method_arn, token)
    except Exception as e:
        print(f"Authorization denied: {e}")
        return _policy("Deny", method_arn, token)


def _validate_jwt(token: str):
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("Invalid JWT format")

    header = json.loads(_b64decode(parts[0]))
    payload = json.loads(_b64decode(parts[1]))

    # 1. Check expiry
    if payload.get("exp", 0) < time.time():
        raise ValueError("Token expired")

    # 2. Check issuer
    issuer = os.environ["ISSUER"]
    if payload.get("iss") != issuer:
        raise ValueError(f"Invalid issuer: {payload.get('iss')}")

    # 3. Check required scope
    required_scope = os.environ.get("REQUIRED_SCOPE", "")
    token_scopes = payload.get("scope", "").split()
    if required_scope and required_scope not in token_scopes:
        raise ValueError(f"Missing required scope: {required_scope}")

    # 4. Verify signature using Cognito public key
    kid = header.get("kid")
    jwks = _get_jwks()
    key = next((k for k in jwks["keys"] if k["kid"] == kid), None)
    if not key:
        raise ValueError(f"No matching key found for kid: {kid}")

    _verify_signature(token, key)


def _verify_signature(token: str, key: dict):
    """
    Verifies RS256 JWT signature using the Cognito public key.
    Uses only stdlib — no external dependencies needed in Lambda.
    """
    import hmac
    import hashlib
    import struct

    parts = token.split(".")
    message = f"{parts[0]}.{parts[1]}".encode()
    signature = _b64decode(parts[2])

    # Decode RSA public key components from JWK
    n = int.from_bytes(_b64decode(key["n"]), "big")
    e = int.from_bytes(_b64decode(key["e"]), "big")

    # RSA verify: signature^e mod n should equal SHA256 hash with PKCS1v15 padding
    sig_int = int.from_bytes(signature, "big")
    decrypted = pow(sig_int, e, n)

    # Reconstruct expected PKCS1v15 padded hash
    digest = hashlib.sha256(message).digest()
    key_size = (n.bit_length() + 7) // 8

    # SHA-256 DER prefix
    der_prefix = bytes([
        0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86,
        0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05,
        0x00, 0x04, 0x20
    ])
    padded = (
        b"\x00\x01"
        + b"\xff" * (key_size - len(der_prefix) - len(digest) - 3)
        + b"\x00"
        + der_prefix
        + digest
    )
    expected = int.from_bytes(padded, "big")

    if decrypted != expected:
        raise ValueError("JWT signature verification failed")


def _get_jwks() -> dict:
    global _jwks_cache, _jwks_cache_ttl
    now = time.time()
    if _jwks_cache and now < _jwks_cache_ttl:
        return _jwks_cache

    jwks_uri = os.environ["JWKS_URI"]
    with urllib.request.urlopen(jwks_uri, timeout=5) as resp:
        _jwks_cache = json.loads(resp.read())
        _jwks_cache_ttl = now + _CACHE_SECONDS
    return _jwks_cache


def _b64decode(s: str) -> bytes:
    # Add padding if needed
    s += "=" * (4 - len(s) % 4)
    return urlsafe_b64decode(s)


def _policy(effect: str, method_arn: str, token: str = "") -> dict:
    arn_parts = method_arn.split(":")
    region = arn_parts[3]
    account = arn_parts[4]
    api_stage = "/".join(arn_parts[5].split("/")[:2])
    resource_arn = f"arn:aws:execute-api:{region}:{account}:{api_stage}/*/*"

    # Extract sub/client_id for principalId if possible
    principal = "anonymous"
    if token:
        try:
            parts = token.split(".")
            payload = json.loads(_b64decode(parts[1]))
            principal = payload.get("sub", payload.get("client_id", "anonymous"))
        except Exception:
            pass

    return {
        "principalId": principal,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [{
                "Action": "execute-api:Invoke",
                "Effect": effect,
                "Resource": resource_arn,
            }],
        },
        "context": {
            "authorized": str(effect == "Allow"),
            "principalId": principal,
        },
    }
