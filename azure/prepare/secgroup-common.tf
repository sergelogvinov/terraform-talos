
resource "azurerm_subnet_network_security_group_association" "public" {
  for_each                  = { for idx, name in var.regions : name => idx }
  subnet_id                 = azurerm_subnet.public[each.key].id
  network_security_group_id = azurerm_network_security_group.common[each.key].id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  for_each                  = { for idx, name in var.regions : name => idx }
  subnet_id                 = azurerm_subnet.private[each.key].id
  network_security_group_id = azurerm_network_security_group.common[each.key].id
}

resource "azurerm_network_security_group" "common" {
  for_each            = { for idx, name in var.regions : name => idx }
  location            = each.key
  name                = "common-${each.key}"
  resource_group_name = azurerm_resource_group.kubernetes.name

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_network_security_rule" "common_icmp" {
  for_each                    = { for idx, name in var.regions : name => idx }
  resource_group_name         = azurerm_resource_group.kubernetes.name
  network_security_group_name = azurerm_network_security_group.common[each.key].name

  name                       = "icmp"
  priority                   = 1000
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Icmp"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "common_ssh" {
  for_each                    = { for idx, name in var.regions : name => idx }
  resource_group_name         = azurerm_resource_group.kubernetes.name
  network_security_group_name = azurerm_network_security_group.common[each.key].name

  name                       = "ssh"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  source_address_prefix      = "*"
  destination_port_range     = "22"
  destination_address_prefix = "*"
}

# resource "azurerm_network_security_rule" "common_kubelet_v4" {
#   for_each                    = { for idx, name in var.regions : name => idx }
#   resource_group_name         = azurerm_resource_group.kubernetes.name
#   network_security_group_name = azurerm_network_security_group.common[each.key].name

#   name                       = "kubelet-v4"
#   priority                   = 1011
#   direction                  = "Inbound"
#   access                     = "Allow"
#   protocol                   = "Tcp"
#   source_port_range          = "*"
#   source_address_prefix      = var.network_cidr[0]
#   destination_port_range     = "10250"
#   destination_address_prefix = "*"
# }
# resource "azurerm_network_security_rule" "common_kubelet_v6" {
#   for_each                    = { for idx, name in var.regions : name => idx }
#   resource_group_name         = azurerm_resource_group.kubernetes.name
#   network_security_group_name = azurerm_network_security_group.common[each.key].name

#   name                       = "kubelet-v6"
#   priority                   = 1012
#   direction                  = "Inbound"
#   access                     = "Allow"
#   protocol                   = "Tcp"
#   source_port_range          = "*"
#   source_address_prefix      = var.network_cidr[1]
#   destination_port_range     = "10250"
#   destination_address_prefix = "*"
# }

# resource "azurerm_network_security_rule" "common_cilium_health_v4" {
#   for_each                    = { for idx, name in var.regions : name => idx }
#   resource_group_name         = azurerm_resource_group.kubernetes.name
#   network_security_group_name = azurerm_network_security_group.common[each.key].name

#   name                       = "cilium-health-v4"
#   priority                   = 1021
#   direction                  = "Inbound"
#   access                     = "Allow"
#   protocol                   = "Tcp"
#   source_port_range          = "*"
#   source_address_prefix      = var.network_cidr[0]
#   destination_port_range     = "4240"
#   destination_address_prefix = "*"
# }
# resource "azurerm_network_security_rule" "common_cilium_health_v6" {
#   for_each                    = { for idx, name in var.regions : name => idx }
#   resource_group_name         = azurerm_resource_group.kubernetes.name
#   network_security_group_name = azurerm_network_security_group.common[each.key].name

#   name                       = "cilium-health-v6"
#   priority                   = 1022
#   direction                  = "Inbound"
#   access                     = "Allow"
#   protocol                   = "Tcp"
#   source_port_range          = "*"
#   source_address_prefix      = var.network_cidr[1]
#   destination_port_range     = "4240"
#   destination_address_prefix = "*"
# }

# resource "azurerm_network_security_rule" "common_cilium_vxvlan_v4" {
#   for_each                    = { for idx, name in var.regions : name => idx }
#   resource_group_name         = azurerm_resource_group.kubernetes.name
#   network_security_group_name = azurerm_network_security_group.common[each.key].name

#   name                       = "cilium-vxvlan"
#   priority                   = 1023
#   direction                  = "Inbound"
#   access                     = "Allow"
#   protocol                   = "Udp"
#   source_port_range          = "*"
#   source_address_prefix      = var.network_cidr[0]
#   destination_port_range     = "8472"
#   destination_address_prefix = "*"
# }
