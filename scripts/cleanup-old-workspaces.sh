#!/bin/bash
set -e

# List all workspaces
WORKSPACES=$(terraform workspace list)

# Keep only last 5 feature branch workspaces
for workspace in $WORKSPACES; do
  if [[ $workspace != "default" && $workspace != "production" && $workspace != "staging" && $workspace != "dev" ]]; then
    WORKSPACE_COUNT=$(($WORKSPACE_COUNT + 1))
    if [ $WORKSPACE_COUNT -gt 5 ]; then
      echo "Cleaning up workspace: $workspace"
      terraform workspace select $workspace
      terraform destroy -auto-approve
      terraform workspace select default
      terraform workspace delete $workspace
    fi
  fi
done

# Clean up old plan files
find . -name "tfplan*" -mtime +7 -delete
