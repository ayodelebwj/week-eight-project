#!/bin/bash
#========================================
#THIS COMMANDS CREATES THE JENKINS SERVER
#========================================
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -var-file="values.tfvars" --auto-approve