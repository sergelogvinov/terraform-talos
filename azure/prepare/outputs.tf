
output "regions" {
  description = "Regions"
  value       = var.regions
}

output "network_public" {
  description = "The public network"
  value = { for zone, subnet in azurerm_subnet.public : zone => {
    network_id = subnet.id
    cidr       = subnet.address_prefixes
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
