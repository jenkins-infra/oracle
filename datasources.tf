# All resources of this project are contained within a "compartment", child of the tenant
# The compartment ID is provided through variables, but we also need to retrive the name in 'current_compartment_name
data "oci_identity_compartments" "all" {
  compartment_id = var.tenancy_ocid
  access_level   = "ACCESSIBLE"
  state          = "ACTIVE"
}
locals {
  current_compartment_name = element([for c in data.oci_identity_compartments.all.compartments : c.name if c.id == var.compartment_ocid], 0)
}

# Availability zone allows highly available system to be split in different "zones"
# At least 1 is required, hence the datasource to refer it
data "oci_identity_availability_domain" "availability_domain" {
  compartment_id = var.compartment_ocid
  ad_number      = 1
}
