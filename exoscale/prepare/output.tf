
output "project" {
  description = "Exoscale project name"
  value       = var.project
}

output "regions" {
  description = "Exoscale regions"
  value       = var.regions
}

output "network" {
  description = "List of network"
  value = { for zone, net in exoscale_private_network.main : zone => {
    name    = net.name
    id      = net.id
    cidr    = cidrsubnet("${net.start_ip}/24", 0, 0)
    gateway = cidrhost("${exoscale_private_network.main[zone].start_ip}/24", -3)
  } }
}

output "secgroups" {
  description = "List of secgroups"
  value = { for zone, net in exoscale_private_network.main : zone => {
    common       = exoscale_security_group.common.id
    controlplane = exoscale_security_group.controlplane.id
    web          = exoscale_security_group.web.id
  } }
}
