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
resource "oci_core_subnet" "internal_subnet" {
  cidr_block                 = "10.0.10.0/24"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.default.id
  freeform_tags              = local.all_tags
  prohibit_public_ip_on_vnic = true
}

data "oci_core_private_ips" "get_privates_ip_id" {
  ip_address = oci_core_instance.updates_jenkins_io.private_ip
  subnet_id  = oci_core_subnet.public_subnet.id
}

resource "oci_core_public_ip" "VMupdate_ip" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "Update VM public ip"
  freeform_tags  = local.all_tags
  private_ip_id  = data.oci_core_private_ips.get_privates_ip_id.private_ips[0].id
}

resource "oci_core_network_security_group" "VM_network_security_group" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.default.id
  display_name   = "Update VM security group"
  freeform_tags  = local.all_tags
}

resource "oci_core_network_security_group_security_rule" "ssh" {
  network_security_group_id = oci_core_network_security_group.VM_network_security_group.id

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
output "instance_public_ip" {
  value = oci_core_instance.updates_jenkins_io.public_ip
}
