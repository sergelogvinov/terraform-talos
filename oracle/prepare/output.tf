
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

output "network_lb" {
  description = "The lb network"
  value       = oci_core_subnet.regional_lb
}

output "network_public" {
  description = "The public network"
  value       = oci_core_subnet.public
}

output "network_private" {
  description = "The private network"
  value       = oci_core_subnet.private
}

output "nsg_cilium" {
  description = "The cilium Network Security Groups"
  value       = oci_core_network_security_group.cilium.id
}

output "nsg_talos" {
  description = "The talos Network Security Groups"
  value       = oci_core_network_security_group.talos.id
}

output "nsg_contolplane_lb" {
  description = "The contolplane-lb Network Security Groups"
  value       = oci_core_network_security_group.contolplane_lb.id
}

output "nsg_contolplane" {
  description = "The contolplane Network Security Groups"
  value       = oci_core_network_security_group.contolplane.id
}

output "nsg_web" {
  description = "The web Network Security Groups"
  value       = oci_core_network_security_group.web.id
}
