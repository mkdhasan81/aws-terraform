"""
Lambda Authorizer — TOKEN type
Validates the Authorization header bearer token against the expected token
stored in the AUTHORIZER_TOKEN environment variable.

To swap in real JWT validation later, replace the token comparison
with a JWT decode + signature verification step.
"""

import os
import re


def handler(event, context):
    token = event.get("authorizationToken", "")
    method_arn = event.get("methodArn", "")

    expected = os.environ.get("AUTHORIZER_TOKEN", "")

    # Strip "Bearer " prefix if present
    if token.lower().startswith("bearer "):
        token = token[7:]

    if token and token == expected:
        return _policy("Allow", method_arn)

    return _policy("Deny", method_arn)


def _policy(effect: str, method_arn: str) -> dict:
    # Wildcard the ARN so one token grants access to all methods/stages
    arn_parts = method_arn.split(":")
    region = arn_parts[3]
    account = arn_parts[4]
    api_stage = "/".join(arn_parts[5].split("/")[:2])
    resource_arn = f"arn:aws:execute-api:{region}:{account}:{api_stage}/*/*"

    return {
        "principalId": "user",
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": effect,
                    "Resource": resource_arn,
                }
            ],
        },
        "context": {"authorized": str(effect == "Allow")},
    }
