
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = try(scaleway_lb_ip.lb[0].ip_address, "127.0.0.1")
}

output "controlplanes" {
  description = "Kubernetes controlplane first node"
  value       = try(flatten([for c in scaleway_instance_ip.controlplane : c.address]), "none")
}
