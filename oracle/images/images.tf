
resource "oci_objectstorage_object" "talos_amd64" {
  bucket      = oci_objectstorage_bucket.images.name
  namespace   = data.oci_objectstorage_namespace.ns.namespace
  object      = "talos-amd64.qcow2"
  source      = "oracle-amd64.qcow2"
  content_md5 = filemd5("oracle-amd64.qcow2")
}

resource "oci_objectstorage_object" "talos_arm64" {
  bucket      = oci_objectstorage_bucket.images.name
  namespace   = data.oci_objectstorage_namespace.ns.namespace
  object      = "talos-arm64.qcow2"
  source      = "oracle-arm64.qcow2"
  content_md5 = filemd5("oracle-arm64.qcow2")
}

resource "oci_core_image" "talos_amd64" {
  compartment_id = var.compartment_ocid

  display_name = "Talos-amd64"
  launch_mode  = "PARAVIRTUALIZED"

  image_source_details {
    source_type    = "objectStorageTuple"
    namespace_name = oci_objectstorage_bucket.images.namespace
    bucket_name    = oci_objectstorage_bucket.images.name
    object_name    = oci_objectstorage_object.talos_amd64.object

    operating_system         = "Talos"
    operating_system_version = "1.3.0"
    source_image_type        = "QCOW2"
  }

  timeouts {
    create = "30m"
  }
}

resource "oci_core_image" "talos_arm64" {
  compartment_id = var.compartment_ocid

  display_name = "Talos-arm64"
  launch_mode  = "PARAVIRTUALIZED"

  image_source_details {
    source_type    = "objectStorageTuple"
    namespace_name = oci_objectstorage_bucket.images.namespace
    bucket_name    = oci_objectstorage_bucket.images.name
    object_name    = oci_objectstorage_object.talos_arm64.object

    operating_system         = "Talos"
    operating_system_version = "1.3.0"
    source_image_type        = "QCOW2"
  }

  timeouts {
    create = "30m"
  }
}

data "oci_core_compute_global_image_capability_schemas" "default" {}
data "oci_core_compute_global_image_capability_schemas_version" "default" {
  compute_global_image_capability_schema_id           = data.oci_core_compute_global_image_capability_schemas.default.compute_global_image_capability_schemas[0].id
  compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas.default.compute_global_image_capability_schemas[0].current_version_name
}

resource "oci_core_compute_image_capability_schema" "talos_amd64" {
  compartment_id                                      = var.compartment_ocid
  compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas.default.compute_global_image_capability_schemas[0].current_version_name

  display_name = "Talos-amd64"
  image_id     = oci_core_image.talos_amd64.id
  schema_data = {
    "Storage.BootVolumeType" = "{\"descriptorType\":\"enumstring\",\"values\":[\"SCSI\",\"IDE\",\"PARAVIRTUALIZED\"],\"defaultValue\":\"PARAVIRTUALIZED\",\"source\":\"IMAGE\"}",
  }
}

resource "oci_core_compute_image_capability_schema" "talos_arm64" {
  compartment_id                                      = var.compartment_ocid
  compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas.default.compute_global_image_capability_schemas[0].current_version_name

  display_name = "Talos-arm64"
  image_id     = oci_core_image.talos_arm64.id
  schema_data = {
    "Storage.BootVolumeType" = "{\"descriptorType\":\"enumstring\",\"values\":[\"SCSI\",\"IDE\",\"PARAVIRTUALIZED\"],\"defaultValue\":\"PARAVIRTUALIZED\",\"source\":\"IMAGE\"}",
  }
}

resource "oci_core_shape_management" "talos_arm64" {
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.talos_arm64.id
  shape_name     = "VM.Standard.A1.Flex"
}
