
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint public"
  value       = try(local.endpoints[0], "127.0.0.1")
}

output "controlplane_endpoint_public" {
  description = "Kubernetes controlplane endpoint public"
  value       = local.endpoints
}
