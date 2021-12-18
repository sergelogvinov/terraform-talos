
resource "oci_objectstorage_object" "talos_amd64" {
  bucket      = oci_objectstorage_bucket.images.name
  namespace   = data.oci_objectstorage_namespace.ns.namespace
  object      = "talos-amd64.qcow2"
  source      = "oracle-amd64.qcow2"
  content_md5 = filemd5("oracle-amd64.qcow2")
}

resource "oci_core_image" "talos_amd64" {
  compartment_id = var.tenancy_ocid

  display_name = "Talos-amd64"
  launch_mode  = "NATIVE"

  image_source_details {
    source_type    = "objectStorageTuple"
    namespace_name = oci_objectstorage_bucket.images.namespace
    bucket_name    = oci_objectstorage_bucket.images.name
    object_name    = oci_objectstorage_object.talos_amd64.object

    operating_system         = "Talos"
    operating_system_version = "0.14.0"
    source_image_type        = "QCOW2"
  }

  timeouts {
    create = "30m"
  }
}

# resource "oci_core_compute_image_capability_schema" "talos_amd64" {
#   compartment_id = var.tenancy_ocid

#   compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas_version.default.name

#   display_name = "Talos-amd64"
#   image_id     = oci_core_image.talos_amd64.id

#   schema_data = {
#     "Storage.BootVolumeType" = "{\"descriptorType\":\"enumstring\",\"values\":[\"SCSI\",\"IDE\",\"PARAVIRTUALIZED\"],\"defaultValue\":\"PARAVIRTUALIZED\",\"source\":\"GLOBAL\"}",
#   }
# }

# data "oci_core_compute_image_capability_schemas" "talos_amd64" {
#   compartment_id = var.tenancy_ocid
#   image_id       = oci_core_image.talos_amd64.id
# }

# data "oci_core_compute_global_image_capability_schemas_versions" "default" {
#   compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schema.default.id
# }

# data "oci_core_compute_global_image_capability_schemas" "default" {
#   display_name = "OCI.ComputeGlobalImageCapabilitySchema"
# }

# data "oci_core_compute_global_image_capability_schema" "default" {
#   compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schemas.default.compute_global_image_capability_schemas[0].id
# }

# data "oci_core_compute_global_image_capability_schemas_version" "default" {
#   compute_global_image_capability_schema_id           = data.oci_core_compute_global_image_capability_schema.default.id
#   compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas_versions.default.compute_global_image_capability_schema_versions[0].name
# }

# data "oci_core_compute_image_capability_schema" "test_compute_image_capability_schema" {
#   compute_image_capability_schema_id = oci_core_compute_image_capability_schema.test_compute_image_capability_schema.id
#   is_merge_enabled                   = "true"
# }

# resource "oci_core_compute_image_capability_schema" "test_compute_image_capability_schema" {
#   compartment_id                                      = var.tenancy_ocid
#   compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas_versions.test_compute_global_image_capability_schemas_versions_datasource.compute_global_image_capability_schema_versions[0].name
#   display_name                                        = "displayName"
#   image_id                                            = oci_core_image.talos_amd64.id

#   schema_data = {
#     "Storage.BootVolumeType" = "{\"descriptorType\":\"enumstring\",\"values\":[\"SCSI\",\"IDE\",\"PARAVIRTUALIZED\"],\"defaultValue\":\"PARAVIRTUALIZED\",\"source\":\"GLOBAL\"}",
#   }
# }

# data "oci_core_compute_global_image_capability_schemas_version" "test_compute_global_image_capability_schemas_version_datasource" {
#   compute_global_image_capability_schema_id           = data.oci_core_compute_global_image_capability_schema.test_compute_global_image_capability_schema_datasource.id
#   compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas_versions.test_compute_global_image_capability_schemas_versions_datasource.compute_global_image_capability_schema_versions[0].name
# }

# data "oci_core_compute_global_image_capability_schemas_versions" "test_compute_global_image_capability_schemas_versions_datasource" {
#   compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schema.test_compute_global_image_capability_schema_datasource.id
# }

# data "oci_core_compute_global_image_capability_schema" "test_compute_global_image_capability_schema_datasource" {
#   compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schemas.test_compute_global_image_capability_schemas_datasource.compute_global_image_capability_schemas[0].id
# }

# data "oci_core_compute_global_image_capability_schemas" "test_compute_global_image_capability_schemas_datasource" {
# }
