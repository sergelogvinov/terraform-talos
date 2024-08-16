
output "registries" {
  description = "Registry name"
  value = [for repo in oci_artifacts_container_repository.registry :
    try("${local.region}.ocir.io/${data.oci_artifacts_container_configuration.registry.namespace}/${repo.display_name}", "")
  ]
}

output "backup" {
  description = "Backup bucket name"
  value = {
    bucket   = oci_objectstorage_bucket.backup.name,
    region   = local.region,
    endpoint = "https://${data.oci_objectstorage_namespace.namespace.namespace}.compat.objectstorage.${local.region}.oraclecloud.com",
  }
}
