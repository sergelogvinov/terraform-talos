
output "worker_endpoints" {
  description = "Kubernetes worker endpoint"
  value       = [for ip in try(openstack_networking_port_v2.worker[*].all_fixed_ips, []) : ip]
}
