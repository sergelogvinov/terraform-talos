
data "azurerm_client_config" "terraform" {}

data "azurerm_shared_image_version" "talos" {
  for_each            = toset(var.arch)
  name                = "latest"
  image_name          = "talos-${lower(each.key)}"
  gallery_name        = var.gallery_name
  resource_group_name = local.resource_group
}

resource "azurerm_proximity_placement_group" "common" {
  for_each            = { for idx, name in local.regions : name => idx }
  location            = each.key
  name                = "common-${lower(each.key)}"
  resource_group_name = local.resource_group

  tags = merge(var.tags)
}
