
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = try(local.lbv4, "127.0.0.1")
}

output "controlplane_firstnode" {
  description = "Kubernetes controlplane first node"
  value       = try(scaleway_instance_ip.controlplane[0].address, "none")
}

# output "controlplane_nodes" {
#   description = "Kubernetes controlplane nodes"
#   value = [
#     for s in hcloud_server.controlplane[*] :
#     {
#       name         = s.name
#       ipv4_address = s.ipv4_address
#       ipv6_address = s.ipv6_address
#       zone         = "hetzner"
#       location     = s.location
#       params       = ""
#     }
#   ]
# }
