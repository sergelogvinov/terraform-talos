
resource "random_id" "registry" {
  byte_length = 8
}

resource "azurerm_container_registry" "registry" {
  name                = "registry${random_id.registry.hex}"
  resource_group_name = local.resource_group
  location            = local.regions[0]
  sku                 = "Basic"
  admin_enabled       = false

  tags = var.tags
}

data "azurerm_container_registry_scope_map" "pull" {
  name                    = "_repositories_pull"
  resource_group_name     = local.resource_group
  container_registry_name = azurerm_container_registry.registry.name
}

resource "azurerm_container_registry_token" "containerd" {
  name                    = "containerd"
  resource_group_name     = local.resource_group
  container_registry_name = azurerm_container_registry.registry.name
  scope_map_id            = data.azurerm_container_registry_scope_map.pull.id
}

resource "azurerm_container_registry_token_password" "containerd" {
  container_registry_token_id = azurerm_container_registry_token.containerd.id

  password1 {}
}
