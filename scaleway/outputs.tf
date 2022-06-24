
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = try(scaleway_lb_ip.lb[0].ip_address, "127.0.0.1")
}

output "controlplane_firstnode" {
  description = "Kubernetes controlplane first node"
  value       = try(scaleway_instance_ip.controlplane[0].address, "none")
}
