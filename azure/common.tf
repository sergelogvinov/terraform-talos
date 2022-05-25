
# data "azurerm_image" "talos" {
#   for_each            = { for idx, name in local.regions : name => idx }
#   name                = "talos-amd64-${each.key}"
#   resource_group_name = local.resource_group
# }

data "azurerm_shared_image_version" "talos" {
  name                = "latest"
  image_name          = "talos"
  gallery_name        = "293f5f4eea925204"
  resource_group_name = local.resource_group
}

data "azurerm_client_config" "terraform" {}
