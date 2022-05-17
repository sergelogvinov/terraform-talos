
resource "azurerm_virtual_network" "main" {
  for_each            = { for idx, name in var.regions : name => idx }
  location            = each.key
  name                = "main-${each.value}"
  address_space       = [cidrsubnet(var.network_cidr[0], 6, var.network_shift + each.value * 4), cidrsubnet(var.network_cidr[1], 6, var.network_shift + each.value * 4)]
  resource_group_name = azurerm_resource_group.kubernetes.name

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_subnet" "public" {
  for_each             = { for idx, name in var.regions : name => idx }
  name                 = "public"
  resource_group_name  = azurerm_resource_group.kubernetes.name
  virtual_network_name = azurerm_virtual_network.main[each.key].name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.main[each.key].address_space[0], 2, 0), cidrsubnet(azurerm_virtual_network.main[each.key].address_space[1], 2, 0)]
}

resource "azurerm_subnet" "private" {
  for_each             = { for idx, name in var.regions : name => idx }
  name                 = "private"
  resource_group_name  = azurerm_resource_group.kubernetes.name
  virtual_network_name = azurerm_virtual_network.main[each.key].name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.main[each.key].address_space[0], 2, 1), cidrsubnet(azurerm_virtual_network.main[each.key].address_space[1], 2, 1)]
}

resource "azurerm_virtual_network_peering" "peering" {
  for_each                     = { for idx, name in var.regions : name => idx }
  name                         = "peering-from-${each.key}"
  resource_group_name          = azurerm_resource_group.kubernetes.name
  virtual_network_name         = azurerm_virtual_network.main[each.key].name
  remote_virtual_network_id    = element([for network in azurerm_virtual_network.main : network.id if network.location != each.key], 0)
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_route_table" "link" {
  for_each            = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  location            = each.key
  name                = "link-${each.value}"
  resource_group_name = azurerm_resource_group.kubernetes.name

  dynamic "route" {
    for_each = range(0, length(var.network_cidr))

    content {
      name                   = "link-${each.value}-${route.value}"
      address_prefix         = var.network_cidr[route.value]
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = cidrhost(azurerm_subnet.public[each.key].address_prefixes[route.value], -2)
    }
  }

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_subnet_route_table_association" "public" {
  for_each       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  subnet_id      = azurerm_subnet.public[each.key].id
  route_table_id = azurerm_route_table.link[each.key].id
}

resource "azurerm_subnet_route_table_association" "private" {
  for_each       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  subnet_id      = azurerm_subnet.private[each.key].id
  route_table_id = azurerm_route_table.link[each.key].id
}
