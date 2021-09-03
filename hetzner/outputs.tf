
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = local.lbv4
  depends_on  = [hcloud_load_balancer.api]
}

output "controlplane_nodes" {
  description = "Kubernetes controlplane nodes"
  value = [
    for s in hcloud_server.controlplane[*] :
    {
      name         = s.name
      ipv4_address = s.ipv4_address
      ipv6_address = s.ipv6_address
      zone         = "hetzner"
      location     = s.location
      params       = ""
    }
  ]
}
