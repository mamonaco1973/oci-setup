# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Does

Deploys a minimal OCI compute instance running Apache via cloud-init. Creates a full network stack (VCN → IGW → Route Table → Security List → Subnet) and a `VM.Standard.E2.1.Micro` instance (Always Free eligible) with a public IP.

## Commands

```bash
./apply.sh      # validate env, init, and apply
./destroy.sh    # teardown all resources
./validate.sh   # poll http://<instance_ip> and print banner
```

SSH to the instance:
```bash
ssh -i ./keys/Private_Key ubuntu@<instance_public_ip>
```

## Architecture

Single `main.tf` — no modules, no workspaces. Everything deploys into one compartment.

**Network chain:** `oci_core_vcn` → `oci_core_internet_gateway` → `oci_core_route_table` → `oci_core_security_list` → `oci_core_subnet`

Security List attaches at the **subnet** level (not instance level like AWS Security Groups). Ingress: TCP 22, TCP 80. Egress: all.

**Compute:** Ubuntu image resolved dynamically via `oci_core_images` data source (filtered by shape + OS version, sorted newest-first). Availability domain resolved via `oci_identity_availability_domains` data source — OCI requires explicit AD selection.

`user_data` in instance `metadata` must be base64-encoded. `scripts/userdata.sh` is the cloud-init script.

## Auth and Variable Wiring

- OCI auth: `~/.oci/config` DEFAULT profile — no credentials in code
- Compartment: set `OCI_COMPARTMENT_ID` env var; scripts translate it to `TF_VAR_compartment_ocid`
- If `OCI_COMPARTMENT_ID` is unset, scripts fall back to the tenancy OCID read from `~/.oci/config`
- `check_env.sh` only validates — it does **not** export `OCI_COMPARTMENT_ID` (subprocess exports don't propagate to the parent). The awk fallback runs inside `apply.sh` and `destroy.sh` directly.

## Known OCI Quirks

- **cloud-init timing:** OCI fires cloud-init scripts before DNS resolves. `userdata.sh` loops on `nslookup` before running `apt-get`.
- **Ubuntu mirror DDoS (May 2026):** `archive.ubuntu.com` and `security.ubuntu.com` are under sustained DDoS. `userdata.sh` rewrites apt sources to `us.archive.ubuntu.com` via `sed` before installing packages.

## Keys

Terraform generates an ECDSA P-256 key pair via `tls_private_key` on each fresh deploy. The private key is written to `keys/Private_Key` (0600) via `local_file`. The `keys/` directory is gitignored — keys are never committed. No manual key generation needed.
