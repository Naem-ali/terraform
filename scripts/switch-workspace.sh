#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <workspace>"
    exit 1
fi

WORKSPACE=$1

# Create workspace if it doesn't exist
terraform workspace new $WORKSPACE 2>/dev/null || terraform workspace select $WORKSPACE

# Initialize Terraform
terraform init

# Run plan for the workspace
terraform plan -var-file="environments/${WORKSPACE}/terraform.tfvars" -out=tfplan
