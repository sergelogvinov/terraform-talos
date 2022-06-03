
resource "azurerm_private_dns_zone" "main" {
  count               = try(var.capabilities["all"].network_dns_enable, false) ? 1 : 0
  name                = var.domain
  resource_group_name = var.resource_group

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = { for idx, name in var.regions : name => idx if try(var.capabilities["all"].network_dns_enable, false) }
  name                  = "dns-${lower(each.key)}"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.main[0].name
  virtual_network_id    = azurerm_virtual_network.main[each.key].id

  tags = merge(var.tags, { type = "infra" })
}
