
resource "azurerm_network_security_group" "controlplane" {
  for_each            = { for idx, name in var.regions : name => idx }
  location            = each.key
  name                = "controlplane-${each.key}"
  resource_group_name = azurerm_resource_group.kubernetes.name

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

  security_rule {
    name                       = "etcd"
    priority                   = 1550
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "2379-2380"
    destination_address_prefix = "*"
  }

  tags = merge(var.tags, { type = "infra" })
}
