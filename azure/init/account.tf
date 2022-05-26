
resource "azurerm_resource_group" "kubernetes" {
  location = var.regions[0]
  name     = var.project

  tags = var.tags
}

# resource "azurerm_user_assigned_identity" "ccm" {
#   name                = "kubernetes-ccm"
#   resource_group_name = azurerm_resource_group.kubernetes.name
#   location            = azurerm_resource_group.kubernetes.location

#   tags = var.tags
# }

# resource "azurerm_role_assignment" "ccm" {
#   name               = "ea088185-27f1-4956-a58b-150d2ddd8eb3"
#   description        = "kubernetes ccm"
#   scope              = data.azurerm_subscription.current.id
#   role_definition_id = azurerm_role_definition.ccm.role_definition_id
#   principal_id       = azurerm_user_assigned_identity.ccm.principal_id
# }
