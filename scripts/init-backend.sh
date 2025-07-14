#!/bin/bash
set -e

# Check if environment is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

ENV=$1
PROJECT="demo"
REGION="us-west-2"

# Create S3 bucket first (needed for backend)
aws s3api create-bucket \
    --bucket "${PROJECT}-${ENV}-terraform-state" \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "${PROJECT}-${ENV}-terraform-state" \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket "${PROJECT}-${ENV}-terraform-state" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Create KMS key
KMS_KEY_ID=$(aws kms create-key \
    --description "KMS key for Terraform state encryption" \
    --tags TagKey=Environment,TagValue=$ENV TagKey=Project,TagValue=$PROJECT \
    --region $REGION \
    --output text \
    --query 'KeyMetadata.KeyId')

# Create alias for KMS key
aws kms create-alias \
    --alias-name "alias/terraform-state-key" \
    --target-key-id $KMS_KEY_ID \
    --region $REGION

# Update bucket encryption to use KMS
aws s3api put-bucket-encryption \
    --bucket "${PROJECT}-${ENV}-terraform-state" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "aws:kms",
                    "KMSMasterKeyID": "'$KMS_KEY_ID'"
                }
            }
        ]
    }'

# Enable access logging
aws s3api put-bucket-logging \
    --bucket "${PROJECT}-${ENV}-terraform-state" \
    --bucket-logging-status '{
        "LoggingEnabled": {
            "TargetBucket": "'${PROJECT}-${ENV}-terraform-state-logs'",
            "TargetPrefix": "state-logs/"
        }
    }'

# Create DynamoDB table
aws dynamodb create-table \
    --table-name "${PROJECT}-${ENV}-terraform-locks" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION \
    --tags Key=Environment,Value=$ENV Key=Project,Value=$PROJECT

# Enable point-in-time recovery
aws dynamodb update-continuous-backups \
    --table-name "${PROJECT}-${ENV}-terraform-locks" \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
    --region $REGION

echo "Backend infrastructure created successfully!"
