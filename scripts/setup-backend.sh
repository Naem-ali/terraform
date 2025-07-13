#!/bin/bash

# Create S3 bucket for backend
aws s3api create-bucket \
    --bucket terraform-state-bucket-yourname \
    --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket terraform-state-bucket-yourname \
    --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region us-east-1
