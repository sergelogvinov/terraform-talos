
data "oci_identity_availability_domains" "main" {
  compartment_id = var.compartment_ocid
}

locals {
  zones = [for ad in data.oci_identity_availability_domains.main.availability_domains : ad.name]
}

data "oci_core_services" "object_store" {
  filter {
    name   = "name"
    values = ["OCI .* Object Storage"]
    regex  = true
  }
}
