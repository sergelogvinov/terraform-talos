
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = module.controlplane
}

output "controlplane_endpoint_public" {
  description = "Kubernetes controlplane endpoint public"
  value       = try(local.endpoint[0], "127.0.0.1")
}

output "web_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = module.web
}
