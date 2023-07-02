
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
  value = { for region, net in azurerm_virtual_network.main : region => {
    name    = net.name
    nat     = try(azurerm_public_ip.nat[region].ip_address, "")
    dns     = try(azurerm_private_dns_zone.main[0].name, "")
    peering = try(azurerm_linux_virtual_machine.router[region].private_ip_addresses, [])
    cidr    = azurerm_virtual_network.main[region].address_space
  } }
}

output "network_controlplane" {
  description = "The controlplane network"
  value = { for region, subnet in azurerm_subnet.controlplane : region => {
    network_id           = subnet.id
    cidr                 = subnet.address_prefixes
    sku                  = try(var.capabilities[region].network_lb_sku, "Basic")
    controlplane_pool_v4 = try(var.capabilities[region].network_lb_enable, false) ? try(azurerm_lb_backend_address_pool.controlplane_v4[region].id, "") : ""
    controlplane_pool_v6 = try(var.capabilities[region].network_lb_enable, false) ? try(azurerm_lb_backend_address_pool.controlplane_v6[region].id, "") : ""
    controlplane_lb      = try(var.capabilities[region].network_lb_enable, false) ? azurerm_lb.controlplane[region].private_ip_addresses : []
  } }
}

output "network_public" {
  description = "The public network"
  value = { for region, subnet in azurerm_subnet.public : region => {
    network_id = subnet.id
    cidr       = subnet.address_prefixes
    sku        = var.capabilities[region].network_gw_sku
  } }
}

output "network_private" {
  description = "The private network"
  value = { for region, subnet in azurerm_subnet.private : region => {
    network_id = subnet.id
    cidr       = subnet.address_prefixes
    nat        = try(azurerm_public_ip.nat[region].ip_address, "")
    sku        = try(azurerm_public_ip.nat[region].ip_address, "") == "" ? "Standard" : var.capabilities[region].network_gw_sku
  } }
}

output "secgroups" {
  description = "List of secgroups"
  value = { for region, subnet in azurerm_subnet.private : region => {
    common       = azurerm_network_security_group.common[region].id
    controlplane = azurerm_network_security_group.controlplane[region].id
    web          = azurerm_network_security_group.web[region].id
  } }
}
