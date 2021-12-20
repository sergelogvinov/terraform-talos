
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

output "dns_zone_id" {
  description = "DNS zones id"
  value       = oci_dns_zone.cluster.id
}

output "network_nat" {
  description = "The nat IP"
  value       = oci_core_public_ip.nat.ip_address
}

output "network_lb" {
  description = "The lb network"
  value = {
    id                    = oci_core_subnet.regional_lb.id
    cidr_block            = oci_core_subnet.regional_lb.cidr_block
    virtual_router_ip     = oci_core_subnet.regional_lb.virtual_router_ip
    ipv6cidr_block        = oci_core_subnet.regional_lb.ipv6cidr_block
    ipv6virtual_router_ip = oci_core_subnet.regional_lb.ipv6virtual_router_ip
  }
}

output "network_public" {
  description = "The public network"
  value = { for az, network in oci_core_subnet.public : az => {
    id                    = network.id
    cidr_block            = network.cidr_block
    virtual_router_ip     = network.virtual_router_ip
    ipv6cidr_block        = network.ipv6cidr_block
    ipv6virtual_router_ip = network.ipv6virtual_router_ip
    availability_domain   = network.availability_domain
  } }
}

output "network_private" {
  description = "The private network"
  value = { for az, network in oci_core_subnet.private : az => {
    id                    = network.id
    cidr_block            = network.cidr_block
    virtual_router_ip     = network.virtual_router_ip
    ipv6cidr_block        = network.ipv6cidr_block
    ipv6virtual_router_ip = network.ipv6virtual_router_ip
    availability_domain   = network.availability_domain
  } }
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
