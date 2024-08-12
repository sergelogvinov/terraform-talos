
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  #   value       = try(flatten(scaleway_lb_ip.lb[0].ip_address), try(flatten([for c in scaleway_instance_ip.controlplane_v4 : c.address])[0], ""))
  value = try(try(flatten([for c in scaleway_instance_ip.controlplane_v4 : c.address])[0], ""))

}

output "controlplane_firstnode" {
  description = "Kubernetes controlplane first node"
  value       = try(cidrhost(local.main_subnet, 11), "127.0.0.1")
}
