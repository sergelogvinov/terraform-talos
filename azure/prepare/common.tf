
resource "azurerm_ssh_public_key" "terraform" {
  name                = "Terraform"
  resource_group_name = var.resource_group
  location            = var.regions[0]
  public_key          = file("~/.ssh/terraform.pub")

  tags = var.tags

  lifecycle {
    ignore_changes = [public_key]
  }
}
