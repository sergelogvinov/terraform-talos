
resource "google_compute_network" "network" {
  project                  = var.project
  name                     = var.network_name
  description              = "Project ${var.cluster_name}"
  routing_mode             = "REGIONAL"
  mtu                      = 1500
  enable_ula_internal_ipv6 = true
  internal_ipv6_range      = cidrsubnet(var.network_cidr[1], 8, var.network_shift)
  auto_create_subnetworks  = false
}

resource "google_compute_subnetwork" "core" {
  project     = var.project
  name        = "${var.cluster_name}-core-${var.region}"
  region      = var.region
  description = "Core subnet"
  network     = google_compute_network.network.id

  stack_type               = "IPV4_IPV6"
  ipv6_access_type         = "EXTERNAL" # "INTERNAL"
  ip_cidr_range            = cidrsubnet(var.network_cidr[0], 8, 0)
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private" {
  for_each    = toset(data.google_compute_zones.region.names)
  project     = var.project
  name        = "${var.cluster_name}-private-${each.value}"
  region      = var.region
  description = "Private subnet for zone ${each.value}"
  network     = google_compute_network.network.id

  stack_type               = "IPV4_IPV6"
  ipv6_access_type         = "INTERNAL"
  ip_cidr_range            = cidrsubnet(var.network_cidr[0], 8, 2 + index(data.google_compute_zones.region.names, each.value))
  private_ip_google_access = true
}

# resource "google_compute_global_address" "google" {
#   name          = "${var.cluster_name}-private-google"
#   purpose       = "VPC_PEERING"
#   ip_version    = "IPV4"
#   address       = cidrhost(cidrsubnet(var.network_cidr[0], 8, 1), 0)
#   address_type  = "INTERNAL"
#   prefix_length = 24
#   network       = google_compute_network.network.id
# }

# resource "google_service_networking_connection" "private_vpc_connection" {
#   network                 = google_compute_network.network.id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.google.name]
# }
