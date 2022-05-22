
# data "azurerm_image" "talos" {
#   for_each            = { for idx, name in local.regions : name => idx }
#   name                = "talos-amd64-${each.key}"
#   resource_group_name = local.resource_group
# }
