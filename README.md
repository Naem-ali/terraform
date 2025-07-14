# AWS Infrastructure as Code with Terraform

This project contains Terraform configurations for deploying a complete AWS infrastructure including VPC, ECS, ALB, monitoring, and security components.

## Prerequisites

- AWS CLI installed and configured
- Terraform >= 1.0
- tfsec (optional, for security scanning)
- Git

## Project Structure

```
/home/nick/Terraform/
├── infra/
│   ├── modules/
│   │   ├── acm/                 # SSL/TLS certificate management
│   │   ├── alb/                 # Application Load Balancer
│   │   ├── auto_healing/        # Auto recovery mechanisms
│   │   ├── backend_config/      # State management and locking
│   │   ├── cloudwatch_logs/     # Logging and monitoring
│   │   ├── config/             # AWS Config rules
│   │   ├── cost/               # Cost management
│   │   ├── ecs/                # Container services
│   │   ├── guardduty/          # Security monitoring
│   │   ├── kms/                # Key Management Service
│   │   │   ├── main.tf         # KMS key creation and policies
│   │   │   ├── variables.tf    # KMS configuration variables
│   │   │   └── outputs.tf      # KMS outputs
│   │   ├── mutex_lock/         # State locking mechanism
│   │   ├── network_firewall/   # Network security
│   │   ├── route53/            # DNS management
│   │   ├── s3_logs/           # Log storage
│   │   ├── security_groups/    # Security group management
│   │   ├── sns/                # Notification service
│   │   ├── state_management/   # Terraform state configuration
│   │   ├── tags/              # Resource tagging
│   │   ├── vpc/               # Network infrastructure
│   │   └── xray/              # Distributed tracing
│   │
│   ├── environments/
│   │   ├── dev/               # Development environment
│   │   │   ├── backend.tf     # Backend configuration
│   │   │   ├── data.tf        # Data sources
│   │   │   ├── main.tf        # Main configuration
│   │   │   ├── providers.tf   # Provider configuration
│   │   │   ├── variables.tf   # Variable definitions
│   │   │   └── workspace.tf   # Workspace settings
│   │   │
│   │   ├── staging/          # Staging environment
│   │   └── prod/            # Production environment
│   │
│   └── global/              # Global configurations
│       ├── backend/         # Backend setup
│       └── iam/             # IAM configurations
│
├── scripts/
│   ├── backend/
│   │   ├── init-backend.sh          # Backend initialization
│   │   └── setup-state-lock.sh      # DynamoDB lock setup
│   │
│   ├── cleanup/
│   │   ├── cleanup-old-workspaces.sh # Workspace management
│   │   └── cleanup-state.sh         # State file cleanup
│   │
│   ├── validation/
│   │   ├── validate.sh              # Configuration validation
│   │   └── security-check.sh        # Security validation
│   │
│   └── deployment/
│       ├── switch-workspace.sh      # Workspace switching
│       └── test-infrastructure.sh   # Infrastructure testing
│
├── .gitignore              # Git ignore patterns
├── .gitlab-ci.yml          # GitLab CI/CD pipeline
├── .pre-commit-config.yaml # Pre-commit hooks
├── Makefile               # Common commands
└── README.md              # Project documentation
```

## Quick Start

1. **Setup Backend Infrastructure**
```bash
# Initialize backend infrastructure
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh
```

2. **Configure Variables**
- Copy and update environment variables:
```bash
cd infra/environments/dev
cp terraform.tfvars.example terraform.tfvars
```
- Update `terraform.tfvars` with your values
- Update domain name in Route53 configuration

3. **Initialize Terraform**
```bash
terraform init
```

4. **Validate Configuration**
```bash
chmod +x scripts/validate.sh
./scripts/validate.sh
```

5. **Deploy Infrastructure**
```bash
terraform apply tfplan
```

## Modules

- **VPC**: Network infrastructure
- **ECS**: Container orchestration
- **ALB**: Load balancing
- **Route53**: DNS management
- **ACM**: SSL/TLS certificates
- **CloudWatch**: Monitoring and logging
- **GuardDuty**: Security monitoring
- **Config**: Compliance rules
- **Auto Healing**: Self-healing infrastructure
- **KMS**: Key Management Service

## Key Management Service (KMS)

### Overview
The project includes a centralized KMS module for managing encryption keys across services:

1. **Service-Specific Keys**:
   - S3 bucket encryption
   - RDS database encryption
   - EBS volume encryption
   - Secrets Manager encryption
   - Lambda environment variables
   - CloudWatch Logs encryption

2. **Key Features**:
   - Automatic key rotation
   - Multi-region support
   - Custom retention periods
   - Service principal access
   - IAM role separation

3. **Security Controls**:
   - Administrator/User separation
   - Service-specific policies
   - Customizable key policies
   - Deletion protection

### Usage Example
```hcl
module "kms" {
  source = "../../modules/kms"
  
  project = "demo"
  env     = "dev"
  
  # Key configurations for different services
  keys = {
    s3 = {
      description = "S3 encryption key"
      service_principals = ["s3"]
    }
    # Additional key configurations...
  }
}
```

### Key Management
- Key creation and rotation
- Access policy management
- Service integration
- Monitoring and logging

## Environment Management

- Development: `terraform workspace select dev`
- Staging: `terraform workspace select staging`
- Production: `terraform workspace select prod`

## Security Features

- WAF protection
- Network firewall
- GuardDuty enabled
- SSL/TLS encryption
- Private subnets
- Security groups
- NACLs

## Monitoring & Logging

- CloudWatch logs
- X-Ray tracing
- CloudWatch alarms
- Auto healing
- Performance metrics

## Backup & Recovery

- S3 versioning
- State file backup
- Multi-AZ deployment
- Auto healing

## Cost Management

- Cost allocation tags
- Budget alerts
- Dev environment auto-shutdown
- Resource optimization

## CI/CD Pipeline Integration

### GitLab CI Pipeline
The project uses GitLab CI for automated pipelines with extensive stages:

1. **Lint Stage**
   - Terraform format checking
   - TFLint for extended validation
   - Ensures code quality standards

2. **Security Stage**
   - TFSec scanning
   - Checkov policy checks
   - Scheduled security scans
   - Security reports generation

3. **Validation Stage**
   - Terraform configuration validation
   - Backend validation
   - Resource verification

4. **Plan Stage**
   - Infrastructure plan generation
   - Workspace management
   - Plan artifacts storage
   - JSON report generation

5. **Cost Stage**
   - Infrastructure cost estimation
   - Cost report generation
   - Budget validation

6. **Approval Stage**
   - Manual approval gate
   - Production deployment protection
   - Change review process

7. **Apply Stage**
   - Infrastructure deployment
   - Environment tracking
   - Deployment URLs
   - State management

8. **Test Stage**
   - Integration testing
   - Infrastructure validation
   - Service health checks
   - DNS verification

9. **Cleanup Stage**
   - Workspace management
   - Old plan cleanup
   - Resource optimization

### Pipeline Features

```bash
# View pipeline status
gitlab-cli pipeline list

# View specific pipeline
gitlab-cli pipeline show <pipeline-id>

# View security reports
gitlab-cli security report

# Check cost estimation
gitlab-cli artifacts download cost.json

# Run manual cleanup
gitlab-cli job run cleanup
```

### Environment Protection
- Production deployments require approval
- Manual intervention for critical stages
- Environment-specific configurations
- Scheduled security checks

### Pipeline Artifacts
- Terraform plans
- Security reports
- Cost estimations
- Test results
- Infrastructure state

### Cache Management
- Terraform plugins
- Provider caches
- State file caching
- Plan artifacts

### Pipeline Stages
1. **Validate**:
   - Syntax checking
   - Format validation
   - Security scanning
   
2. **Plan**:
   - Infrastructure plan generation
   - Plan artifact storage
   - Change review

3. **Apply**:
   - Manual approval required
   - Production safeguards
   - State file backup

### Local Development Pipeline
Pre-commit hooks and local validation:
```bash
# Install pre-commit hooks
pre-commit install

# Run local validation
make validate
make lint
```

## Deployment Process

1. **Development**:
   ```bash
   # Switch to dev workspace
   ./scripts/switch-workspace.sh dev
   
   # Deploy changes
   make plan
   make apply
   ```

2. **Staging/Production**:
   - Create pull request
   - Wait for CI validation
   - Get approval
   - Merge to main
   - Automated deployment

## State Management and Mutex Locking

### Backend Configuration
The project uses a secure S3 backend with DynamoDB for state locking:

- **State Storage**: S3 with encryption and versioning
- **State Locking**: DynamoDB with global tables
- **Security**: KMS encryption and access logging

```bash
# Initialize backend for new environment
./scripts/init-backend.sh dev
```

### Features

1. **S3 Backend**
   - Versioning enabled
   - Server-side encryption
   - Access logging
   - Lifecycle management
   - Public access blocked

2. **DynamoDB Locking**
   - Global tables for multi-region support
   - Point-in-time recovery
   - TTL for stale locks
   - Auto-scaling enabled
   - Encryption at rest

3. **Security Measures**
   - KMS key rotation
   - Access logging
   - IAM role separation
   - Encryption in transit
   - Bucket policies

### Workspace Management
```bash
# Create/switch workspace
terraform workspace new dev
terraform workspace select dev

# List workspaces
terraform workspace list
```

### State Operations
```bash
# Force unlock state
terraform force-unlock [LOCK_ID]

# List state
terraform state list

# Show state
terraform state show [RESOURCE]
```

### Best Practices
- Use unique state files per environment
- Enable versioning for rollback capability
- Implement state locking
- Regular state backups
- Monitor lock timeouts
- Clean up old state files

## Pipeline Security Features
- Environment protection rules
- Manual approval for production
- Secrets management
- Security scanning
- Compliance checks

## Best Practices

1. Always run `validate.sh` before applying changes
2. Use workspaces for environment separation
3. Review security group rules regularly
4. Monitor CloudWatch logs and metrics
5. Keep state files backed up
6. Use Git for version control

## Troubleshooting

Common issues and solutions:

1. **Backend Initialization Fails**
```bash
terraform init -reconfigure
```

2. **State Lock Issues**
```bash
terraform force-unlock [LOCK_ID]
```

3. **Resource Cleanup**
```bash
terraform destroy -target=MODULE.RESOURCE_NAME
```

## Maintenance

Regular tasks:
- Update provider versions
- Review security groups
- Check CloudWatch logs
- Monitor costs
- Update SSL certificates
- Review access logs

## Contributing

1. Create a feature branch
2. Make changes
3. Run validation script
4. Submit pull request
5. Wait for review

