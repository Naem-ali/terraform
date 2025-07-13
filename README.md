# Fullstack Terraform Project

A complete fullstack project using Terraform, AWS, and GitHub Actions.

## 🔧 Environments
- `dev`
- `test`

## 🧱 Infrastructure
- VPC, EC2, S3, RDS
- S3 + DynamoDB for Terraform backend

## 🚀 How to Use

```bash
make init
make plan
make apply
```

## 📦 CI/CD
GitHub Actions auto-applies Terraform on push to main.
