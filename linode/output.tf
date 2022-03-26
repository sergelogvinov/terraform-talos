
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = local.lbv4
}
