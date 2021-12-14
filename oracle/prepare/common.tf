
data "oci_identity_availability_domains" "main" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_services" "main" {
  filter {
    name   = "name"
    values = ["OCI .* Object Storage"]
    regex  = true
  }
}
