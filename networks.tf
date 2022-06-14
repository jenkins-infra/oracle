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
