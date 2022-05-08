
output "controlplane_endpoints" {
  description = "Kubernetes controlplane endpoint"
  value       = [for ip in try(openstack_networking_port_v2.controlplane_public[*].all_fixed_ips, []) : ip]
  depends_on  = [openstack_networking_port_v2.controlplane_public]
}

output "controlplane_bootstrap" {
  description = "Kubernetes controlplane bootstrap command"
  value       = local.ipv4_local == "" ? "" : "talosctl apply-config --insecure --nodes ${local.ipv4_local} --file _cfgs/controlplane-${lower(var.region)}-1.yaml"
  depends_on  = [openstack_networking_port_v2.controlplane_public]
}
