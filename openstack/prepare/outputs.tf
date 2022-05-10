
output "regions" {
  description = "Regions"
  value       = var.regions
}

output "network" {
  value = { for zone, network in local.network_id : zone => {
    name = var.network_name
    id   = network.id
    cidr = var.network_cidr
    mtu  = network.mtu
  } }
}

output "network_external" {
  description = "The public network"
  value = { for zone, subnet in data.openstack_networking_network_v2.external : zone => {
    name       = var.network_name_external
    id         = subnet.id
    subnets    = sort(subnet.subnets)
    subnets_v6 = sort(data.openstack_networking_subnet_ids_v2.external_v6[zone].ids)
    mtu        = subnet.mtu
  } }
}

output "network_public" {
  description = "The public network"
  value = { for zone, subnet in openstack_networking_subnet_v2.public : zone => {
    network_id = subnet.network_id
    subnet_id  = subnet.id
    cidr       = subnet.cidr
    gateway    = subnet.gateway_ip != "" ? subnet.gateway_ip : cidrhost(subnet.cidr, 1)
    mtu        = local.network_id[zone].mtu
  } }
}

output "network_private" {
  description = "The private network"
  value = { for zone, subnet in openstack_networking_subnet_v2.private : zone => {
    network_id = subnet.network_id
    subnet_id  = subnet.id
    cidr       = subnet.cidr
    gateway    = subnet.gateway_ip != "" ? subnet.gateway_ip : cidrhost(subnet.cidr, 1)
    mtu        = local.network_id[zone].mtu
  } }
}
