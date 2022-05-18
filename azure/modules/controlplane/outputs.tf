
output "controlplane_endpoints" {
  description = "Kubernetes controlplane endpoint"
  value       = local.ipv4_public
}

output "controlplane_bootstrap" {
  description = "Kubernetes controlplane bootstrap command"
  value       = length(local.ipv4_public) > 0 ? "talosctl apply-config --insecure --nodes ${local.ipv4_public[0]} --file _cfgs/controlplane-${lower(var.region)}-1.yaml" : ""
  depends_on  = [azurerm_linux_virtual_machine.controlplane]
}
