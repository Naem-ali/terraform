#!/bin/bash
set -e

# Check if environment is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

ENV=$1

# Create or select workspace
terraform workspace new $ENV || terraform workspace select $ENV

# Initialize backend
terraform init \
    -backend-config="key=${ENV}/terraform.tfstate" \
    -backend-config="workspace_key_prefix=workspaces" \
    -backend=true \
    -force-copy

echo "Workspace $ENV initialized successfully!"
