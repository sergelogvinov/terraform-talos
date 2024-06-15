
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = try(one(local.controlplane_v6), "")
}

output "controlplane_endpoints" {
  description = "Kubernetes controlplane endpoints"
  value       = try(local.controlplane_v4, [])
}

output "controlplane_firstnode" {
  description = "Kubernetes controlplane first node"
  value       = try(flatten([for s in local.controlplanes : [s.ipv6, s.ipv4]])[0], "127.0.0.1")
}

output "controlplane_lbv4" {
  description = "Kubernetes controlplane loadbalancer"
  value       = try(local.lbv4, "")
}

output "subnets" {
  value = local.subnets
}
