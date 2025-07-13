init:
	cd infra/environments/dev && terraform init

plan:
	cd infra/environments/dev && terraform plan

apply:
	cd infra/environments/dev && terraform apply -auto-approve

destroy:
	cd infra/environments/dev && terraform destroy -auto-approve
