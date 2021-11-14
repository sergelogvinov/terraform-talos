
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = local.lbv4
  depends_on  = [openstack_networking_port_v2.vip]
}
