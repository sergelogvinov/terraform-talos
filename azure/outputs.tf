
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = module.controlplane
}

output "controlplane_endpoint_public" {
  description = "Kubernetes controlplane endpoint public"
  value       = local.endpoint
}

# output "ipv4_local" {
#   value = local.ipv4_local
# }

# output "web_endpoint" {
#   description = "Kubernetes controlplane endpoint"
#   value       = module.web
# }
