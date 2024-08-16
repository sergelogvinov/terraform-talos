
resource "oci_objectstorage_object" "talos" {
  for_each = toset(var.arch)

  bucket      = oci_objectstorage_bucket.images.name
  namespace   = data.oci_objectstorage_namespace.ns.namespace
  object      = "talos-${lower(each.key)}.oci"
  source      = "oracle-${lower(each.key)}.oci"
  content_md5 = filemd5("oracle-${lower(each.key)}.oci")
}

resource "oci_core_image" "talos" {
  for_each       = toset(var.arch)
  compartment_id = var.compartment_ocid
  display_name   = "Talos-${lower(each.key)}"
  defined_tags   = local.tags
  freeform_tags  = { "OS" : "Talos", "Arch" : lower(each.key) }
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type    = "objectStorageTuple"
    namespace_name = oci_objectstorage_bucket.images.namespace
    bucket_name    = oci_objectstorage_bucket.images.name
    object_name    = oci_objectstorage_object.talos[each.key].object

    operating_system         = "Talos"
    operating_system_version = var.release
    source_image_type        = "QCOW2"
  }

  lifecycle {
    ignore_changes = [
      defined_tags,
    ]
    replace_triggered_by = [oci_objectstorage_object.talos[each.key].content_md5]
  }

  timeouts {
    create = "30m"
  }
}

# data "oci_core_compute_global_image_capability_schemas" "default" {}
# data "oci_core_compute_global_image_capability_schemas_version" "default" {
#   compute_global_image_capability_schema_id           = data.oci_core_compute_global_image_capability_schemas.default.compute_global_image_capability_schemas[0].id
#   compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas.default.compute_global_image_capability_schemas[0].current_version_name
# }

# resource "oci_core_compute_image_capability_schema" "talos_amd64" {
#   compartment_id                                      = var.compartment_ocid
#   compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas.default.compute_global_image_capability_schemas[0].current_version_name

#   display_name = "Talos-amd64"
#   image_id     = oci_core_image.talos_amd64.id
#   schema_data = {
#     "Storage.BootVolumeType"         = "{\"descriptorType\":\"enumstring\",\"values\":[\"SCSI\",\"IDE\",\"PARAVIRTUALIZED\"],\"defaultValue\":\"PARAVIRTUALIZED\",\"source\":\"IMAGE\"}",
#     "Storage.ConsistentVolumeNaming" = "{\"descriptorType\":\"boolean\",\"defaultValue\":true,\"source\":\"IMAGE\"}"
#   }
# }

# resource "oci_core_compute_image_capability_schema" "talos_arm64" {
#   compartment_id                                      = var.compartment_ocid
#   compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas.default.compute_global_image_capability_schemas[0].current_version_name

#   display_name = "Talos-arm64"
#   image_id     = oci_core_image.talos_arm64.id
#   schema_data = {
#     "Storage.BootVolumeType" = "{\"descriptorType\":\"enumstring\",\"values\":[\"SCSI\",\"IDE\",\"PARAVIRTUALIZED\"],\"defaultValue\":\"PARAVIRTUALIZED\",\"source\":\"IMAGE\"}",
#   }
# }

# resource "oci_core_shape_management" "talos_arm64" {
#   compartment_id = var.compartment_ocid
#   image_id       = oci_core_image.talos_arm64.id
#   shape_name     = "VM.Standard.A1.Flex"
# }
