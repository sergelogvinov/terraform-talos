
provider "azurerm" {
  features {}
  subscription_id = local.subscription_id
}

# data "azurerm_virtual_machine_size" "size" {
#   name     = "Standard_D2pls_v5"
#   location = "westeurope"
# }

# resource "azurerm_linux_virtual_machine_scale_set" "worker" {

#   source_image_reference {
#     location  = "westeurope"
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-${data.azurerm_virtual_machine_size.size.architecture == "Arm64" ? "arm64" : "gen2"}"
#     version   = "latest"
#   }
# }
