
resource "random_string" "backup" {
  length  = 16
  numeric = false
  special = false
  upper   = false
}

data "oci_objectstorage_namespace" "namespace" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "backup" {
  compartment_id = var.compartment_ocid
  name           = random_string.registry.result
  namespace      = data.oci_objectstorage_namespace.namespace.namespace
  defined_tags   = merge(local.tags, { "Kubernetes.Type" = "project", "Kubernetes.Role" = "backup" })

  access_type  = "NoPublicAccess"
  auto_tiering = "Disabled"
  storage_tier = "Standard"
  versioning   = "Disabled"

  lifecycle {
    ignore_changes = [
      defined_tags,
    ]
  }
}

resource "oci_objectstorage_object_lifecycle_policy" "test_object_lifecycle_policy" {
  bucket    = oci_objectstorage_bucket.backup.name
  namespace = data.oci_objectstorage_namespace.namespace.namespace

  rules {
    action      = "DELETE"
    is_enabled  = "true"
    name        = "Clean all objects"
    time_amount = "30"
    time_unit   = "DAYS"
    target      = "objects"
  }

  rules {
    action      = "ABORT"
    is_enabled  = "true"
    name        = "Abort incomplete multipart uploads"
    time_amount = "2"
    time_unit   = "DAYS"
    target      = "multipart-uploads"
  }
}
