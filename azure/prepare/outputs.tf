
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
  value       = azurerm_resource_group.kubernetes.name
}

output "network_public" {
  description = "The public network"
  value = { for zone, subnet in azurerm_subnet.public : zone => {
    network_id        = subnet.id
    cidr              = subnet.address_prefixes
    controlplane_pool = azurerm_lb_backend_address_pool.controlplane_v4[zone].id
    controlplane_lb   = azurerm_lb.controlplane[zone].private_ip_addresses
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
