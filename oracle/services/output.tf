
output "registry" {
  description = "Registry name"
  value       = "https://${var.region}.ocir.io/${data.oci_artifacts_container_configuration.registry.namespace}/${oci_artifacts_container_repository.registry.display_name}"
}
