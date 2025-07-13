#!/bin/bash

# Add error checking
set -e

echo "🔍 Validating Terraform configuration..."

# Check for required tools
command -v terraform >/dev/null 2>&1 || { echo "Terraform is required but not installed. Aborting." >&2; exit 1; }

# Verify AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { echo "AWS credentials not configured. Aborting." >&2; exit 1; }

# Initialize modules
terraform init -backend=false

# Validate syntax
terraform validate

# Run format check
terraform fmt -check -recursive

# Run security scan with tfsec
if command -v tfsec &> /dev/null; then
    echo "Running security scan..."
    tfsec .
fi

# Run plan
terraform plan -out=tfplan -var-file="env/dev.tfvars"
