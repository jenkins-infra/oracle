# Creating a network implies creating implicit resources
# https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformbestpractices_topic-vcndefaults.htm#managing_default_vcn_resources
resource "oci_core_vcn" "default" {
  compartment_id = var.compartment_ocid
  display_name   = "default network for compartment ${local.current_compartment_name}"
  cidr_blocks    = ["10.0.0.0/16"]
  freeform_tags  = local.all_tags
}

# Sub network use to communicate with the outside world
resource "oci_core_subnet" "public_subnet" {
  cidr_block                 = "10.0.0.0/24"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.default.id
  freeform_tags              = local.all_tags
  prohibit_public_ip_on_vnic = false

}

# Sub network use to communicate machine to machine internally
resource "oci_core_subnet" "private_subnet" {
  cidr_block                 = "10.0.10.0/24"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.default.id
  freeform_tags              = local.all_tags
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_network_security_group_security_rule" "ssh_smerle" {
  network_security_group_id = oci_core_network_security_group.updates_jenkins_io.id

  description = "SSH"
  direction   = "INGRESS"
  protocol    = 6 #TCP
  source_type = "CIDR_BLOCK"
  source      = "82.64.5.129/32"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ssh_bastion" {
  network_security_group_id = oci_core_network_security_group.updates_jenkins_io.id

  description = "SSH"
  direction   = "INGRESS"
  protocol    = 6 #TCP
  source_type = "CIDR_BLOCK"
  source      = "52.87.139.201/32"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_internet_gateway" "network_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.default.id
  enabled        = true
  display_name   = "Public network gateway"
  freeform_tags  = local.all_tags
}


resource "oci_core_default_route_table" "network_route_table" {
  manage_default_resource_id = oci_core_subnet.public_subnet.route_table_id

  compartment_id = var.compartment_ocid

  display_name  = "Public network route table"
  freeform_tags = local.all_tags
  route_rules {
    network_entity_id = oci_core_internet_gateway.network_gateway.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}
