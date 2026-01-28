#!/usr/bin/env bash
set -euo pipefail

# Bootstrap S3 state bucket and DynamoDB lock table for Terraform/Terragrunt
# Usage: ./scripts/bootstrap-state.sh [REGION]

REGION="${1:-eu-west-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="platform-k8s-gw-poc-tf-state-${ACCOUNT_ID}"
TABLE_NAME="platform-k8s-gw-poc-tf-state-${ACCOUNT_ID}"

echo "Account:  ${ACCOUNT_ID}"
echo "Region:   ${REGION}"
echo "Bucket:   ${BUCKET_NAME}"
echo "Table:    ${TABLE_NAME}"
echo ""

# Create S3 bucket
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "S3 bucket '${BUCKET_NAME}' already exists."
else
  echo "Creating S3 bucket '${BUCKET_NAME}'..."
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
  else
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi

  aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  aws s3api put-public-access-block --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

  echo "S3 bucket created."
fi

# Create DynamoDB table
if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  echo "DynamoDB table '${TABLE_NAME}' already exists."
else
  echo "Creating DynamoDB table '${TABLE_NAME}'..."
  aws dynamodb create-table \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"

  aws dynamodb wait table-exists --table-name "${TABLE_NAME}" --region "${REGION}"
  echo "DynamoDB table created."
fi

echo ""
echo "Bootstrap complete. You can now run terragrunt commands."
