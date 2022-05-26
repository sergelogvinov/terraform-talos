
output "controlplane_endpoints" {
  description = "Kubernetes controlplane endpoint"
  value       = var.instance_count > 0 ? try([for ip in azurerm_public_ip.controlplane_v4 : ip.ip_address if ip.ip_address != ""], []) : []
  depends_on  = [azurerm_linux_virtual_machine.controlplane]
}

output "controlplane_bootstrap" {
  description = "Kubernetes controlplane bootstrap command"
  value = var.instance_count > 0 ? try([
    for n, ip in azurerm_public_ip.controlplane_v4 : "talosctl apply-config --insecure --nodes ${ip.ip_address} --file _cfgs/controlplane-${lower(var.region)}-${n + 1}.yaml" if ip.ip_address != ""
  ]) : []
  depends_on = [azurerm_linux_virtual_machine.controlplane]
}
