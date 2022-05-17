
resource "azurerm_public_ip" "nat" {
  for_each                = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_nat_enable, false) }
  location                = each.key
  name                    = "nat-${each.value}"
  resource_group_name     = azurerm_resource_group.kubernetes.name
  sku                     = "Standard"
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_nat_gateway" "nat" {
  for_each                = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_nat_enable, false) }
  location                = each.key
  name                    = "nat-${each.value}"
  resource_group_name     = azurerm_resource_group.kubernetes.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 30

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  for_each             = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_nat_enable, false) }
  nat_gateway_id       = azurerm_nat_gateway.nat[each.key].id
  public_ip_address_id = azurerm_public_ip.nat[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  for_each       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_nat_enable, false) }
  subnet_id      = azurerm_subnet.private[each.key].id
  nat_gateway_id = azurerm_nat_gateway.nat[each.key].id
}
