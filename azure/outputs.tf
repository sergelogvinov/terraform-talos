
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = module.controlplane
}

output "controlplane_endpoint_public" {
  description = "Kubernetes controlplane endpoint public"
  value       = local.endpoint
}

output "web_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = compact([for lb in azurerm_public_ip.web_v4 : lb.ip_address])
}
