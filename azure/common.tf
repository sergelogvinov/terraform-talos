
# data "azurerm_image" "talos" {
#   for_each            = { for idx, name in local.regions : name => idx }
#   name                = "talos-amd64-${each.key}"
#   resource_group_name = local.resource_group
# }

# data "azurerm_shared_image" "talos" {
#   name                = "talos-arm64"
#   gallery_name        = var.gallery_name
#   resource_group_name = local.resource_group
# }

data "azurerm_shared_image_version" "talos" {
  name                = "latest"
  image_name          = "talos-x64"
  gallery_name        = var.gallery_name
  resource_group_name = local.resource_group
}

# data "azurerm_shared_image_version" "talos_arm" {
#   name                = "latest"
#   image_name          = "talos-arm64"
#   gallery_name        = var.gallery_name
#   resource_group_name = local.resource_group
# }

data "azurerm_client_config" "terraform" {}

resource "azurerm_proximity_placement_group" "common" {
  for_each            = { for idx, name in local.regions : name => idx }
  location            = each.key
  name                = "common-${lower(each.key)}"
  resource_group_name = local.resource_group

  tags = merge(var.tags)
}
