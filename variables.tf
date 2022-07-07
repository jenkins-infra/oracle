# warning the image ocid is depending on the region !
variable "region" {
  type        = string
  description = "An OCI region"
}

variable "tenancy_ocid" {
  type        = string
  description = "The tenancy (root compartment) OCID"
  sensitive   = true
}

variable "compartment_ocid" {
  type        = string
  description = "The compartment OCID where to use for resources"
  sensitive   = true
}

variable "user_ocid" {
  type        = string
  description = "An OCI user OCID"
  sensitive   = true
}

variable "private_key_path" {
  type        = string
  description = "An OCI private key path"
  sensitive   = true
}

variable "fingerprint" {
  type        = string
  description = "An OCI fingerprint"
  sensitive   = true
}
