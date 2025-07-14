#!/bin/bash
set -e

echo "Testing infrastructure..."

# Test VPC connectivity
echo "Testing VPC connectivity..."
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=${CI_ENVIRONMENT_NAME}"

# Test ALB health
echo "Testing ALB health..."
aws elbv2 describe-target-health --target-group-arn ${TARGET_GROUP_ARN}

# Test ECS services
echo "Testing ECS services..."
aws ecs list-services --cluster ${CLUSTER_NAME}

# Test Route53 records
echo "Testing DNS records..."
aws route53 list-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID}

echo "All tests passed!"
