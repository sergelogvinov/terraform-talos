
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = one([for ip in local.ips : ip if length(split(".", ip)) > 1])
}

output "controlplane_endpoint_public" {
  description = "Kubernetes controlplane endpoint public"
  value       = one([for ip in local.endpoint : ip if length(split(".", ip)) > 1])
}

output "web_endpoint" {
  description = "Kubernetes web endpoint"
  value       = local.web_endpoint
}
