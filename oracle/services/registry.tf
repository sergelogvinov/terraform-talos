
resource "random_id" "registry" {
  byte_length = 8
}

data "oci_artifacts_container_configuration" "registry" {
  compartment_id = var.compartment_ocid
}

resource "oci_artifacts_container_repository" "registry" {
  compartment_id = var.compartment_ocid
  display_name   = "registry-${random_id.registry.hex}"
  is_immutable   = false
  is_public      = false

  readme {
    content = "Container registry for ${var.project}"
    format  = "text/plain"
  }
}
