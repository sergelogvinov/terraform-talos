
output "controlplane_endpoints" {
  description = "Kubernetes controlplane endpoints"
  value       = try([for ip in azurerm_public_ip.controlplane_v4 : ip.ip_address if ip.ip_address != ""], [])
}

output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoints"
  value = one(flatten([for cp in azurerm_network_interface.controlplane :
    [for ip in cp.ip_configuration : ip.private_ip_address if ip.private_ip_address_version == "IPv4"]
  ]))
}

output "controlplane_bootstrap" {
  description = "Kubernetes controlplane bootstrap command"
  value = try([
    for cp in azurerm_linux_virtual_machine.controlplane : "talosctl apply-config --insecure --nodes ${cp.public_ip_addresses[0]} --timeout 5m0s --config-patch @_cfgs/${cp.name}.yaml --file _cfgs/controlplane.yaml"
  ])

  depends_on = [azurerm_linux_virtual_machine.controlplane]
}

output "controlplane_endpoint_public" {
  description = "Kubernetes controlplane endpoint public"
  value       = try(one([for ip in azurerm_public_ip.controlplane_v4 : ip.ip_address if ip.ip_address != ""]), "127.0.0.1")
}

output "web_endpoint" {
  description = "Web endpoint"
  value       = compact([for lb in azurerm_public_ip.web_v4 : lb.ip_address])
}
