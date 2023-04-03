
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = local.ipv4_vip
}

output "controlplane_nodes" {
  description = "Kubernetes controlplane nodes"
  value = [
    for s in local.controlplanes :
    {
      name         = s.name
      ipv4_address = split("/", s.ipv4)[0]
      zone         = s.zone
    }
  ]
}
