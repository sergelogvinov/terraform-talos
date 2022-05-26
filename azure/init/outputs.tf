
output "resource_group" {
  description = "Azure resource group"
  value       = azurerm_resource_group.kubernetes.name
}

output "role_definition" {
  description = "Kubernetes role definition"
  value = {
    ccm        = azurerm_role_definition.ccm.id
    csi        = azurerm_role_definition.csi.id
    autoscaler = azurerm_role_definition.scaler.id
  }
}
