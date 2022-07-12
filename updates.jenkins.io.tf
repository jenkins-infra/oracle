data "oci_core_images" "updates_jenkins_io" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "20.04"
  state                    = "AVAILABLE"
  shape                    = local.updates_jenkins_io_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  updates_jenkins_io_shape    = "VM.Standard.A1.Flex" #imply ARM
  updates_jenkins_io_hostname = "oracle.updates.jenkins.io"
}

resource "oci_core_volume_backup_policy" "updates_jenkins_io" {
  compartment_id = var.compartment_ocid
  schedules {
    backup_type       = "FULL"
    period            = "ONE_WEEK"
    retention_seconds = "1296000" # 15 * 24 * 60 * 60 = 15 days
  }
  schedules {
    backup_type       = "INCREMENTAL"
    period            = "ONE_DAY"
    retention_seconds = "604800" # 7 * 24 * 60 * 60 = 7 days
  }
  freeform_tags = local.all_tags
}

resource "oci_core_volume" "updates_jenkins_io" {
  compartment_id       = var.compartment_ocid
  availability_domain  = data.oci_identity_availability_domain.availability_domain.name
  display_name         = "Data volume for updates.jenkins.io"
  size_in_gbs          = 1200
  freeform_tags        = local.all_tags
  is_auto_tune_enabled = true
}

resource "oci_core_volume_backup_policy_assignment" "volume_backup_policy_assignment" {
  asset_id  = oci_core_volume.updates_jenkins_io.id
  policy_id = oci_core_volume_backup_policy.updates_jenkins_io.id
}

resource "oci_core_instance" "updates_jenkins_io" {
  availability_domain = data.oci_identity_availability_domain.availability_domain.name
  compartment_id      = var.compartment_ocid
  shape               = local.updates_jenkins_io_shape
  shape_config {
    ocpus         = 4
    memory_in_gbs = 16
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.updates_jenkins_io.images[0].id
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    assign_public_ip = false #will assign a non ephemeral one (RESERVED ip)
    nsg_ids          = [oci_core_network_security_group.updates_jenkins_io.id]
  }
  metadata = {
    ssh_authorized_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFrPRIlP8qplANgNa3IO5c1gh0ZqNNj17RZeYcm+Jcb jenkins-infra-team@googlegroups.com"
    user_data           = base64encode(templatefile("./cloudinit-updates-jenkins-io.tftpl", { hostname = "${local.updates_jenkins_io_hostname}" }))
  }
  display_name  = local.updates_jenkins_io_hostname
  freeform_tags = local.all_tags
}

resource "oci_core_vnic_attachment" "private_vnic_attachment" {
  create_vnic_details {
    display_name  = "private_vnic for updates.jenkins.io"
    freeform_tags = local.all_tags
    nsg_ids       = [oci_core_network_security_group.updates_jenkins_io.id]
    subnet_id     = oci_core_subnet.private_subnet.id
  }
  instance_id  = oci_core_instance.updates_jenkins_io.id
  display_name = "private_vnic attachment for updates.jenkins.io"
}

resource "oci_core_volume_attachment" "updates_jenkins_io_data" {
  # Paravirtualized attachment is expected to automount the data volume (compared to "iscsi")
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.updates_jenkins_io.id
  volume_id       = oci_core_volume.updates_jenkins_io.id
  display_name    = "volume attachment for updates.jenkins.io"
  device          = "/dev/oracleoci/oraclevdb"
}

data "oci_core_private_ips" "updates_jenkins_io" {
  ip_address = oci_core_instance.updates_jenkins_io.private_ip
  subnet_id  = oci_core_subnet.public_subnet.id
}

resource "oci_core_public_ip" "updates_jenkins_io" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = "updates.jenkins.io public ip"
  freeform_tags  = local.all_tags
  private_ip_id  = data.oci_core_private_ips.updates_jenkins_io.private_ips[0].id
}

resource "oci_core_network_security_group" "updates_jenkins_io" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.default.id
  display_name   = "updates.jenkins.io security group"
  freeform_tags  = local.all_tags
}

output "updates_jenkins_io_public_ip" {
  value = oci_core_public_ip.updates_jenkins_io.ip_address
}
