
resource "random_id" "backet" {
  byte_length = 8
}

resource "oci_objectstorage_bucket" "images" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "${var.project}-images-${random_id.backet.hex}"
  access_type    = "NoPublicAccess"
  auto_tiering   = "Disabled"
}
