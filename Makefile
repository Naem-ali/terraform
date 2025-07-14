.PHONY: init plan apply destroy validate lint

init:
	terraform init

plan:
	terraform plan -out=tfplan

apply:
	terraform apply tfplan

destroy:
	terraform destroy

validate:
	terraform validate
	terraform fmt -check -recursive
	tflint --recursive

lint:
	checkov -d .
	tfsec .

test:
	cd test && go test -v ./...

all: validate lint plan
