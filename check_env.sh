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

echo "NOTE: Checking OCI_COMPARTMENT_ID environment variable."
if [ -z "${OCI_COMPARTMENT_ID:-}" ]; then
  # Fall back to tenancy OCID from ~/.oci/config — root compartment is a safe default
  tenancy=$(awk -F'=' '/^tenancy[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2; exit}' ~/.oci/config)
  if [ -z "$tenancy" ]; then
    echo "ERROR: OCI_COMPARTMENT_ID is not set and tenancy could not be read from ~/.oci/config."
    exit 1
  fi
  echo "WARNING: OCI_COMPARTMENT_ID not set — will use tenancy OCID from ~/.oci/config as root compartment."
else
  echo "NOTE: OCI_COMPARTMENT_ID is set."
fi

echo "NOTE: Checking OCI CLI connection."

# oci os ns get is a lightweight call that validates auth without side effects
if ! oci os ns get > /dev/null 2>&1; then
  echo "ERROR: Failed to connect to OCI. Check your ~/.oci/config."
  exit 1
else
  echo "NOTE: Successfully connected to OCI."
fi
