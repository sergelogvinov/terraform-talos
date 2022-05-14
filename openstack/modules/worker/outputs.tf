
output "worker_endpoints" {
  description = "Kubernetes worker endpoint"
  value       = flatten([for ip in try(openstack_networking_port_v2.worker_public[*].all_fixed_ips, []) : ip])
}
