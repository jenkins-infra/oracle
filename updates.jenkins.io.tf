data "oci_core_images" "updates_jenkins_io" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  state                    = "AVAILABLE"
  shape                    = local.updates_jenkins_io_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  updates_jenkins_io_shape = "VM.Standard.A1.Flex" #imply ARM
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
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.availability_domain.name
  display_name        = "Data volume for updates.jenkins.io"
  size_in_gbs         = 1200
  freeform_tags       = local.all_tags
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
  }
  display_name  = "VM for updates.jenkins.io service"
  freeform_tags = local.all_tags
}

resource "oci_core_volume_attachment" "updates_jenkins_io_data" {
  # Paravirtualized attachment is expected to automount the data volume (compared to "iscsi")
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.updates_jenkins_io.id
  volume_id       = oci_core_volume.updates_jenkins_io.id
}
