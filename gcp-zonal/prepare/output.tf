
output "project" {
  description = "Region"
  value       = var.project
}

output "region" {
  description = "Region"
  value       = var.region
}

output "zones" {
  description = "Zones"
  value       = data.google_compute_zones.region.names
}

output "cluster_name" {
  description = "Cluster name"
  value       = var.cluster_name
}

output "network" {
  description = "The VPC network name"
  value       = var.network_name
}

output "network_nat" {
  description = "The nat IPs"
  value       = google_compute_address.nat.address
}

output "network_controlplane" {
  description = "The controlplane network"
  value       = google_compute_subnetwork.core
}

output "networks" {
  description = "The VPC networks"
  value       = google_compute_subnetwork.private
}
