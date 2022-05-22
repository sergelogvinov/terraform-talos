
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
