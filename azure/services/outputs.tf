
output "registry" {
  value = "${azurerm_container_registry.registry.name}.azurecr.io"
}

output "registry_token" {
  value     = azurerm_container_registry_token_password.containerd.password1[0].value
  sensitive = true
}
