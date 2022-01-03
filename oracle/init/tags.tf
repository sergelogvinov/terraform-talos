
resource "oci_identity_tag_namespace" "kubernetes" {
  compartment_id = oci_identity_compartment.project.id
  name           = "Kubernetes"
  description    = "Default kubernetes infrastructure tags"
}

resource "oci_identity_tag" "tags" {
  for_each         = var.tags
  name             = each.key
  description      = each.value
  tag_namespace_id = oci_identity_tag_namespace.kubernetes.id
}
