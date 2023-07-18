
resource "azurerm_network_security_group" "router" {
  for_each            = { for idx, name in var.regions : name => idx }
  location            = each.key
  name                = "router-${each.key}"
  resource_group_name = var.resource_group

  dynamic "security_rule" {
    for_each = var.whitelist_admin
    content {
      name                       = "Icmp-${security_rule.key}"
      priority                   = 1000 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Icmp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_range     = "*"
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.whitelist_admin
    content {
      name                       = "WhitelistAdmin-${security_rule.key}"
      priority                   = 1500 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_ranges    = ["22"]
      destination_address_prefix = "*"
    }
  }

  security_rule {
    name                       = "Wireguard"
    priority                   = 1600
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "443"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.network_cidr
    content {
      name                       = "Peering-${security_rule.key}"
      priority                   = 1700 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_range     = "*"
      destination_address_prefix = security_rule.value
    }
  }
  dynamic "security_rule" {
    for_each = var.network_cidr
    content {
      name                       = "Peering-external-${security_rule.key}"
      priority                   = 1700 + security_rule.key
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_range     = "*"
      destination_address_prefix = security_rule.value
    }
  }

  dynamic "security_rule" {
    for_each = var.network_cidr
    content {
      name                       = "Nat-${security_rule.key}"
      priority                   = 1800 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_range     = "*"
      destination_address_prefix = "*"
    }
  }

  tags = merge(var.tags, { type = "infra" })
}
