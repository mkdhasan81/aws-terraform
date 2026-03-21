#!/usr/bin/env bash
# setup-local-access.sh
# Reads AWS credentials from the access keys CSV and configures the AWS CLI.
# Usage: ./setup-local-access.sh [path/to/accessKeys.csv]
set -euo pipefail

REGION="ap-southeast-1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── 1. Locate the CSV ─────────────────────────────────────────────────────────
# Accept an explicit path as first argument, otherwise search next to this script
if [[ $# -ge 1 ]]; then
  CSV_FILE="$1"
else
  # Find any *accessKeys.csv in the script directory (ignores credentials.csv)
  CSV_FILE=$(find "$SCRIPT_DIR" -maxdepth 1 -iname "*accessKeys.csv" | head -n 1)
fi

if [[ -z "$CSV_FILE" || ! -f "$CSV_FILE" ]]; then
  echo "ERROR: No accessKeys.csv found. Place it next to this script or pass the path as an argument."
  echo "  Usage: $0 path/to/accessKeys.csv"
  exit 1
fi

echo "==> Reading credentials from: $CSV_FILE"

# ── 2. Parse CSV (skip header line) ──────────────────────────────────────────
# Expected format: Access key ID,Secret access key
CSV_LINE=$(tail -n 1 "$CSV_FILE" | tr -d '\r')
AWS_ACCESS_KEY_ID=$(echo "$CSV_LINE" | cut -d',' -f1)
AWS_SECRET_ACCESS_KEY=$(echo "$CSV_LINE" | cut -d',' -f2)

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "ERROR: Could not parse credentials from $CSV_FILE"
  exit 1
fi

echo "==> Access Key ID: $AWS_ACCESS_KEY_ID"

# ── 3. Configure AWS CLI ──────────────────────────────────────────────────────
aws configure set aws_access_key_id     "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region                "$REGION"
aws configure set output                "json"

echo "==> AWS CLI configured for region: $REGION"

# ── 4. Verify identity ────────────────────────────────────────────────────────
echo "==> Verifying AWS identity"
aws sts get-caller-identity

echo ""
echo "Done. Run 'terraform init && terraform apply' from environments/dev to deploy."
