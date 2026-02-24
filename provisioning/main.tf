terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.3.0"
    }
  }

  encryption {
    key_provider "pbkdf2" "key_provider" {
      passphrase = var.passphrase
    }
    method "aes_gcm" "encryption_method" {
      keys = key_provider.pbkdf2.key_provider
    }
    state {
      method   = method.aes_gcm.encryption_method
      enforced = true
    }
  }
}

variable "passphrase" {
  type    = string
  default = ""
}

provider "sops" {}

data "sops_file" "secrets" {
  source_file = "./secrets/tf.yaml"
}

provider "oci" {
  region           = data.sops_file.secrets.data["oci_region"]
  tenancy_ocid     = data.sops_file.secrets.data["tenancy_ocid"]
  user_ocid        = data.sops_file.secrets.data["user_ocid"]
  private_key_path = data.sops_file.secrets.data["private_key_path"]
  fingerprint      = data.sops_file.secrets.data["fingerprint"]
}

resource "oci_identity_compartment" "terraform_compartment" {
  compartment_id = data.sops_file.secrets.data["oci_root_compartment_ocid"]
  description    = "Compartment for Terraform resources"
  name           = "Terraform"
}

resource "oci_core_internet_gateway" "main_vcn_igw" {
  compartment_id = oci_identity_compartment.terraform_compartment.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "Main VCN Internet Gateway"
}

resource "oci_core_network_security_group" "main_vcn_nsg" {
  compartment_id = oci_identity_compartment.terraform_compartment.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "Main VCN Network Security Group"
}

resource "oci_core_network_security_group_security_rule" "main_vcn_nsg_rule" {
  network_security_group_id = oci_core_network_security_group.main_vcn_nsg.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
}

resource "oci_core_default_route_table" "main_vcn_route_table" {
  manage_default_resource_id = oci_core_vcn.main_vcn.default_route_table_id
  compartment_id             = oci_identity_compartment.terraform_compartment.id
  display_name               = "Main VCN Route Table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.main_vcn_igw.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_vcn" "main_vcn" {
  compartment_id = oci_identity_compartment.terraform_compartment.id
  dns_label      = "mainvcn"
  cidr_block     = "172.16.0.0/16"
  display_name   = "Main VCN"
}

resource "oci_core_subnet" "public_instances_subnet" {
  cidr_block     = "172.16.1.0/24"
  compartment_id = oci_identity_compartment.terraform_compartment.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "Public Instances Subnet"

  security_list_ids = [
    oci_core_security_list.access_sec_list.id,
    oci_core_security_list.https_open_sec_list.id,
    oci_core_security_list.self_apps_sec_list.id
  ]
}

data "oci_core_private_ips" "instance_01_private_ip" {
  ip_address = oci_core_instance.instance_01.private_ip
  subnet_id  = oci_core_subnet.public_instances_subnet.id
}

resource "oci_core_public_ip" "instance_01_public_ip" {
  compartment_id = oci_identity_compartment.terraform_compartment.id
  display_name   = "instance-01-public-ip"
  lifetime       = "RESERVED"

  private_ip_id = data.oci_core_private_ips.instance_01_private_ip.private_ips[0].id
}

resource "oci_core_instance" "instance_01" {
  availability_domain = "TNjJ:SA-SANTIAGO-1-AD-1"
  compartment_id      = oci_identity_compartment.terraform_compartment.id
  shape               = "VM.Standard.A1.Flex"
  display_name        = "instance-01"
  metadata = {
    "ssh_authorized_keys" = file("/etc/ssh/authorized_keys.d/cricro")
    "user_data"           = base64encode(file("./cloud_init.yaml"))
  }
  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }
  source_details {
    source_type             = "image"
    source_id               = "ocid1.image.oc1.sa-santiago-1.aaaaaaaagtvea4qbiyduz3e5jawg4q7n4r7tsdbfnsuudn6lxsyv7sg33dga"
    boot_volume_size_in_gbs = 200
  }
  create_vnic_details {
    assign_public_ip = false # !!!
    display_name     = "instance-01-vnic"
    subnet_id        = oci_core_subnet.public_instances_subnet.id

    nsg_ids = [
      oci_core_network_security_group.main_vcn_nsg.id
    ]
  }
}

resource "oci_core_security_list" "access_sec_list" {
  compartment_id = oci_identity_compartment.terraform_compartment.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "Primary access security list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = 6 # TCP
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = 1 # ICMP
    icmp_options {
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    source   = oci_core_vcn.main_vcn.cidr_block
    protocol = 1 # ICMP
    icmp_options {
      type = 3
    }
  }
}

resource "oci_core_security_list" "https_open_sec_list" {
  compartment_id = oci_identity_compartment.terraform_compartment.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "HTTPS open security list"

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = 6 # TCP
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = 6 # TCP
    tcp_options {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_security_list" "self_apps_sec_list" {
  compartment_id = oci_identity_compartment.terraform_compartment.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "Self-Hosted Apps Security List"

  ingress_security_rules {
    description = "Pterodactyl"
    source      = "0.0.0.0/0"
    protocol    = 6 # TCP
    tcp_options {
      min = 27000
      max = 27099
    }
  }

  ingress_security_rules {
    description = "Pterodactyl (UDP)"
    source      = "0.0.0.0/0"
    protocol    = 17 # UDP
    tcp_options {
      min = 27100
      max = 27150
    }
  }

  ingress_security_rules {
    description = "Pterodactyl (SFTP)"
    source      = "0.0.0.0/0"
    protocol    = 6 # TCP
    tcp_options {
      min = 2022
      max = 2022
    }
  }

  ingress_security_rules {
    description = "WireGuard"
    source      = "0.0.0.0/0"
    protocol    = 17 # UDP
    udp_options {
      min = 51820
      max = 51820
    }
  }

  ingress_security_rules {
    description = "RustDesk"
    source      = "0.0.0.0/0"
    protocol    = 6 # TCP
    tcp_options {
      min = 21115
      max = 21119
    }
  }

  ingress_security_rules {
    description = "RustDesk"
    source      = "0.0.0.0/0"
    protocol    = 17 # UDP
    udp_options {
      min = 21116
      max = 21116
    }
  }
}
