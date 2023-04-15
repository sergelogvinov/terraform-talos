
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = local.lbv4
  depends_on  = [hcloud_load_balancer.api]
}

output "controlplane_firstnode" {
  description = "Kubernetes controlplane first node"
  value       = try(flatten([for c in hcloud_server.controlplane : c.ipv4_address])[0], "127.0.0.1")
}
