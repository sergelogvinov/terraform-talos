
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = local.lbv4
}

output "web_endpoint" {
  description = "Web endpoint"
  value       = local.lbv4_web
}
