
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = try(flatten(scaleway_lb_ip.lb[0].ip_address), try(flatten([for c in scaleway_instance_ip.controlplane : c.address])[0], ""))
}

output "controlplanes" {
  description = "Kubernetes controlplane first node"
  value       = try(flatten([for c in scaleway_instance_ip.controlplane : c.address]), "none")
}
