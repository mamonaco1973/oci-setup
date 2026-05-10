#!/bin/bash
set -euo pipefail

# ================================================================================
# Outputs
# Pull the public IP from Terraform state — no cloud CLI needed
# ================================================================================

INSTANCE_IP=$(terraform output -raw instance_public_ip)
INSTANCE_URL="http://${INSTANCE_IP}"

echo "NOTE: Waiting for Apache at ${INSTANCE_URL}..."

# ================================================================================
# Poll
# Apache installs via cloud-init on first boot — allow up to 4 minutes
# ================================================================================

for attempt in {1..24}; do
  if curl -sf "${INSTANCE_URL}" > /dev/null 2>&1; then
    break
  fi
  if [[ "${attempt}" -eq 24 ]]; then
    echo "ERROR: Apache did not respond after 24 attempts (4 minutes)."
    exit 1
  fi
  echo "NOTE: Not ready (attempt ${attempt}/24), retrying in 30 seconds..."
  sleep 30
done

# ================================================================================
# Summary
# ================================================================================

echo ""
echo "================================================================================"
echo "  OCI Setup - Instance Validated"
echo "================================================================================"
echo "  URL : ${INSTANCE_URL}"
echo "================================================================================"
