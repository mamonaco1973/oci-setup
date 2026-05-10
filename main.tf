# ================================================================================
# Provider Configuration
# Auth is read from ~/.oci/config DEFAULT profile — no credentials in code
# ================================================================================

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 6.0"
    }
  }
}

provider "oci" {
  region = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment to deploy resources into"
}

# ================================================================================
# Availability Domain
# OCI requires explicit AD selection — resolved dynamically so this works
# across regions with different numbers of availability domains
# ================================================================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# ================================================================================
# Networking
# VCN → Internet Gateway → Route Table → Security List → Subnet
# OCI has no implicit default network — every component must be created
# ================================================================================

resource "oci_core_vcn" "setup_vcn" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.0.0.0/16"
  display_name   = "setup-vcn"
  # dns_label must be alphanumeric and ≤ 15 chars — forms the VCN's DNS domain
  dns_label      = "setupvcn"
}

resource "oci_core_internet_gateway" "setup_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.setup_vcn.id
  display_name   = "setup-igw"
  enabled        = true
}

resource "oci_core_route_table" "setup_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.setup_vcn.id
  display_name   = "setup-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.setup_igw.id
  }
}

# Security List attaches at the subnet level — unlike AWS Security Groups
# which attach to instances. All instances in the subnet share these rules.
resource "oci_core_security_list" "setup_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.setup_vcn.id
  display_name   = "setup-security-list"

  ingress_security_rules {
    protocol  = "6"           # 6 = TCP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol  = "6"           # 6 = TCP
    source    = "0.0.0.0/0"
    stateless = false
    tcp_options {
      min = 80
      max = 80
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

resource "oci_core_subnet" "setup_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.setup_vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "setup-subnet"
  dns_label         = "setupsubnet"
  route_table_id    = oci_core_route_table.setup_rt.id
  security_list_ids = [oci_core_security_list.setup_sl.id]
}

# ================================================================================
# Compute
# VM.Standard.E2.1.Micro is always-free eligible — 1 OCPU, 1 GB RAM
# Ubuntu image resolved dynamically from Oracle's image catalog
# ================================================================================

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "setup_instance" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  shape               = "VM.Standard.E2.1.Micro"
  display_name        = "setup-instance"

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.setup_subnet.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file("./keys/Public_Key")
    # user_data must be base64-encoded — cloud-init decodes it on first boot
    user_data           = base64encode(file("./scripts/userdata.sh"))
  }
}

# ================================================================================
# Outputs
# ================================================================================

output "instance_public_ip" {
  value       = oci_core_instance.setup_instance.public_ip
  description = "The public IP address of the OCI compute instance"
}
