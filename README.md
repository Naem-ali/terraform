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
│   ├── modules/         # Reusable Terraform modules
│   └── environments/    # Environment-specific configurations
├── scripts/            # Utility scripts
└── docs/              # Documentation
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

## Contact

For support: your.email@example.com

## License

MIT License
