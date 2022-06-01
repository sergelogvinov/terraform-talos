
resource "azurerm_subnet_network_security_group_association" "private" {
  for_each                  = { for idx, name in var.regions : name => idx }
  subnet_id                 = azurerm_subnet.private[each.key].id
  network_security_group_id = azurerm_network_security_group.common[each.key].id
}

resource "azurerm_network_security_group" "common" {
  for_each            = { for idx, name in var.regions : name => idx }
  location            = each.key
  name                = "common-${each.key}"
  resource_group_name = var.resource_group

  dynamic "security_rule" {
    for_each = var.network_cidr
    content {
      name                       = "Kubernetes-tcp-v${length(split(".", security_rule.value)) > 1 ? "4" : "6"}"
      priority                   = 3000 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_ranges    = ["10250"]
      destination_address_prefix = security_rule.value
    }
  }

  dynamic "security_rule" {
    for_each = var.network_cidr
    content {
      name                       = "Cilium-tcp-v${length(split(".", security_rule.value)) > 1 ? "4" : "6"}"
      priority                   = 3100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_ranges    = ["4240"]
      destination_address_prefix = security_rule.value
    }
  }
  dynamic "security_rule" {
    for_each = var.network_cidr
    content {
      name                       = "Cilium-udp-v${length(split(".", security_rule.value)) > 1 ? "4" : "6"}"
      priority                   = 3150 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_ranges    = ["8472"]
      destination_address_prefix = security_rule.value
    }
  }
  dynamic "security_rule" {
    for_each = var.network_cidr
    content {
      name                       = "Cilium-icmp-v${length(split(".", security_rule.value)) > 1 ? "4" : "6"}"
      priority                   = 3190 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Icmp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_range     = "*"
      destination_address_prefix = security_rule.value
    }
  }

  tags = merge(var.tags, { type = "infra" })
}
