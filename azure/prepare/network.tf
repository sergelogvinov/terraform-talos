
resource "azurerm_virtual_network" "main" {
  for_each            = { for idx, name in var.regions : name => idx }
  location            = each.key
  name                = "main-${each.key}"
  address_space       = [cidrsubnet(var.network_cidr[0], 6, var.network_shift + each.value * 4), cidrsubnet(var.network_cidr[1], 6, var.network_shift + each.value * 4)]
  resource_group_name = var.resource_group

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_subnet" "controlplane" {
  for_each             = { for idx, name in var.regions : name => idx }
  name                 = "controlplane"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main[each.key].name
  address_prefixes = [
    for cidr in azurerm_virtual_network.main[each.key].address_space : cidrsubnet(cidr, length(split(".", cidr)) > 1 ? 3 : 2, 0)
  ]
  service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.Storage"]
}

resource "azurerm_subnet" "services" {
  for_each             = { for idx, name in var.regions : name => idx }
  name                 = "services"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main[each.key].name
  address_prefixes = [
    for cidr in azurerm_virtual_network.main[each.key].address_space : cidrsubnet(cidr, 3, 1) if length(split(".", cidr)) > 1
  ]
}

resource "azurerm_subnet" "public" {
  for_each             = { for idx, name in var.regions : name => idx }
  name                 = "public"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main[each.key].name
  address_prefixes = [
    for cidr in azurerm_virtual_network.main[each.key].address_space : cidrsubnet(cidr, 2, 1)
  ]
  service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.Storage"]
}

resource "azurerm_subnet" "private" {
  for_each             = { for idx, name in var.regions : name => idx }
  name                 = "private"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.main[each.key].name
  address_prefixes = [
    for cidr in azurerm_virtual_network.main[each.key].address_space : cidrsubnet(cidr, 2, 2)
  ]
  service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.Storage"]
}

resource "azurerm_virtual_network_peering" "peering" {
  for_each                     = { for idx, name in var.regions : name => idx }
  name                         = "peering-from-${each.key}"
  resource_group_name          = var.resource_group
  virtual_network_name         = azurerm_virtual_network.main[each.key].name
  remote_virtual_network_id    = element([for network in azurerm_virtual_network.main : network.id if network.location != each.key], 0)
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_route_table" "link" {
  for_each            = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  location            = each.key
  name                = "link-${each.key}"
  resource_group_name = var.resource_group

  dynamic "route" {
    for_each = range(0, length(var.network_cidr))

    content {
      name                   = "link-${each.key}-v${length(split(".", var.network_cidr[route.value])) > 1 ? "4" : "6"}"
      address_prefix         = var.network_cidr[route.value]
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = cidrhost(azurerm_subnet.public[each.key].address_prefixes[route.value], -2)
    }
  }

  route {
    name                   = "link-${each.key}-default-v6"
    address_prefix         = "::/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = cidrhost([for ip in azurerm_subnet.public[each.key].address_prefixes : ip if length(split(".", ip)) == 1][0], -2)
  }

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_subnet_route_table_association" "controlplane" {
  for_each       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  subnet_id      = azurerm_subnet.controlplane[each.key].id
  route_table_id = azurerm_route_table.link[each.key].id
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
