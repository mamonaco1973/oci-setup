#!/bin/bash

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# Translate OCI-native var to the name Terraform expects
export TF_VAR_compartment_ocid="$OCI_COMPARTMENT_ID"

terraform init
terraform apply -auto-approve