
output "project" {
  description = "Project name"
  value       = var.project
}

output "region" {
  description = "Region"
  value       = var.region
}

output "zones" {
  description = "Zones"
  value       = local.zones
}

output "network_nat" {
  description = "The nat IP"
  value       = oci_core_public_ip.nat.ip_address
}

output "network_public" {
  description = "The public network"
  value       = oci_core_subnet.public
}

output "network_private" {
  description = "The private network"
  value       = oci_core_subnet.private
}
