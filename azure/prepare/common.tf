
resource "azurerm_resource_group" "kubernetes" {
  location = var.regions[0]
  name     = var.project

  tags = var.tags
}

resource "azurerm_ssh_public_key" "terraform" {
  name                = "Terraform"
  resource_group_name = azurerm_resource_group.kubernetes.name
  location            = var.regions[0]
  public_key          = file("~/.ssh/terraform.pub")

  tags = var.tags
}
