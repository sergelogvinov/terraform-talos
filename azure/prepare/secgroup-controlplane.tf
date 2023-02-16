
resource "azurerm_network_security_group" "controlplane" {
  for_each            = { for idx, name in var.regions : name => idx }
  location            = each.key
  name                = "controlplane-${each.key}"
  resource_group_name = var.resource_group

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
      destination_port_ranges    = ["6443", "50000-50001"]
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    for_each = var.network_cidr
    content {
      name                       = "Kubernetes-v${length(split(".", security_rule.value)) > 1 ? "4" : "6"}"
      priority                   = 1550 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = security_rule.value
      destination_port_ranges    = ["6443", "2379-2380", "50000-50001"]
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
      source_address_prefix      = length(split(".", security_rule.value)) > 1 ? security_rule.value : "::/0"
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
      source_address_prefix      = length(split(".", security_rule.value)) > 1 ? security_rule.value : "::/0"
      destination_port_range     = "*"
      destination_address_prefix = security_rule.value
    }
  }

  tags = merge(var.tags, { type = "infra" })
}
