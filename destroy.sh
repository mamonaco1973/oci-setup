
#!/bin/bash

# Translate OCI-native var to the name Terraform expects
export TF_VAR_compartment_ocid="$OCI_COMPARTMENT_ID"

terraform init
terraform destroy -auto-approve