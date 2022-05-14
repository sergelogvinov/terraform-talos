
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = module.controlplane
}

output "web_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = module.web
}
