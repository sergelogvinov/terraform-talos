
resource "random_string" "registry" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

data "oci_artifacts_container_configuration" "registry" {
  compartment_id = var.compartment_ocid
}

resource "oci_artifacts_container_repository" "registry" {
  for_each       = toset(var.repos)
  compartment_id = var.compartment_ocid
  display_name   = "${random_string.registry.result}/${each.value}"
  defined_tags   = merge(local.tags, { "Kubernetes.Type" = "infra" })
  is_immutable   = false
  is_public      = false

  readme {
    content = "Container mirror of ${each.value}"
    format  = "text/plain"
  }

  lifecycle {
    ignore_changes = [
      defined_tags,
    ]
  }
}
