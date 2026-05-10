#!/bin/bash

echo "NOTE: Validating that required commands are found in your PATH."

commands=("oci" "packer" "terraform")
all_found=true

for cmd in "${commands[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: $cmd is found in the current PATH."
  fi
done

if [ "$all_found" = true ]; then
  echo "NOTE: All required commands are available."
else
  echo "ERROR: One or more commands are missing."
  exit 1
fi

# TF_VAR_compartment_ocid is read by Terraform as var.compartment_ocid
echo "NOTE: Checking TF_VAR_compartment_ocid environment variable."
if [ -z "${TF_VAR_compartment_ocid:-}" ]; then
  echo "ERROR: TF_VAR_compartment_ocid is not set."
  exit 1
else
  echo "NOTE: TF_VAR_compartment_ocid is set."
fi

echo "NOTE: Checking OCI CLI connection."

# oci os ns get is a lightweight call that validates auth without side effects
if ! oci os ns get > /dev/null 2>&1; then
  echo "ERROR: Failed to connect to OCI. Check your ~/.oci/config."
  exit 1
else
  echo "NOTE: Successfully connected to OCI."
fi
