
output "subscription" {
  description = "Azure subscription ID"
  value       = var.subscription_id
}

output "regions" {
  description = "Azure regions"
  value       = var.regions
}

output "resource_group" {
  description = "Azure resource group"
  value       = var.resource_group
}

output "network" {
  description = "The network"
  value = { for zone, net in azurerm_virtual_network.main : zone => {
    name    = net.name
    nat     = try(azurerm_public_ip.nat[zone].ip_address, "")
    dns     = try(azurerm_private_dns_zone.main[0].name, "")
    peering = try(azurerm_linux_virtual_machine.router[zone].private_ip_addresses, [])
  } }
}

output "network_controlplane" {
  description = "The controlplane network"
  value = { for zone, subnet in azurerm_subnet.controlplane : zone => {
    network_id           = subnet.id
    cidr                 = subnet.address_prefixes
    sku                  = azurerm_lb.controlplane[zone].sku
    controlplane_pool_v4 = try(azurerm_lb_backend_address_pool.controlplane_v4[zone].id, "")
    controlplane_pool_v6 = try(azurerm_lb_backend_address_pool.controlplane_v6[zone].id, "")
    controlplane_lb      = azurerm_lb.controlplane[zone].private_ip_addresses
  } }
}

output "network_public" {
  description = "The public network"
  value = { for zone, subnet in azurerm_subnet.public : zone => {
    network_id = subnet.id
    cidr       = subnet.address_prefixes
    sku        = azurerm_lb.controlplane[zone].sku
  } }
}

output "network_private" {
  description = "The private network"
  value = { for zone, subnet in azurerm_subnet.private : zone => {
    network_id = subnet.id
    cidr       = subnet.address_prefixes
    nat        = try(azurerm_public_ip.nat[zone].ip_address, "")
  } }
}

output "secgroups" {
  description = "List of secgroups"
  value = { for zone, subnet in azurerm_subnet.private : zone => {
    common       = azurerm_network_security_group.common[zone].id
    controlplane = azurerm_network_security_group.controlplane[zone].id
    web          = azurerm_network_security_group.web[zone].id
  } }
}
