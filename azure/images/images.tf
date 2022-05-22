
# data "azurerm_resource_group" "kubernetes" {
#   name = var.project
# }

# resource "random_id" "images" {
#   byte_length = 8
# }

# resource "azurerm_storage_account" "images" {
#   for_each                 = { for idx, name in var.regions : name => idx }
#   location                 = each.key
#   name                     = substr("${random_id.images.hex}${each.key}", 0, 24)
#   resource_group_name      = data.azurerm_resource_group.kubernetes.name
#   account_tier             = "Standard"
#   account_replication_type = "LRS"

#   blob_properties {
#     container_delete_retention_policy {
#       days = 1
#     }
#     delete_retention_policy {
#       days = 1
#     }
#   }

#   tags = merge(var.tags, { type = "infra" })
# }

# resource "azurerm_storage_container" "images" {
#   for_each              = { for idx, name in var.regions : name => idx }
#   name                  = lower(var.project)
#   storage_account_name  = azurerm_storage_account.images[each.key].name
#   container_access_type = "private"
# }

# resource "azurerm_storage_blob" "talos" {
#   for_each               = { for idx, name in var.regions : name => idx }
#   name                   = "talos-amd64.vhd"
#   storage_account_name   = azurerm_storage_account.images[each.key].name
#   storage_container_name = azurerm_storage_container.images[each.key].name
#   type                   = "Page"
#   source                 = "${path.module}/disk.vhd"
# }

# resource "azurerm_image" "base" {
#   for_each            = { for idx, name in var.regions : name => idx }
#   location            = each.key
#   name                = "talos-amd64-${each.key}"
#   resource_group_name = data.azurerm_resource_group.kubernetes.name

#   zone_resilient     = false
#   hyper_v_generation = "V2"

#   os_disk {
#     os_type  = "Linux"
#     os_state = "Generalized"
#     blob_uri = azurerm_storage_blob.talos[each.key].url
#     caching  = "ReadWrite"
#     size_gb  = 8
#   }

#   tags = merge(var.tags, { os = "talos" })
# }
