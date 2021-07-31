
resource "google_compute_network" "network" {
  name                    = var.network
  description             = "Project ${var.cluster_name}"
  project                 = var.project_id
  routing_mode            = "REGIONAL"
  mtu                     = 1500
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "core" {
  name                     = "core"
  project                  = var.project_id
  region                   = var.region
  description              = "Core subnet"
  network                  = google_compute_network.network.id
  ip_cidr_range            = cidrsubnet(var.network_cidr, 8, 0)
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private" {
  name                     = "private"
  project                  = var.project_id
  region                   = var.region
  description              = "Private subnet"
  network                  = google_compute_network.network.id
  ip_cidr_range            = cidrsubnet(var.network_cidr, 8, 1)
  private_ip_google_access = true
}

resource "google_compute_global_address" "google" {
  name          = "google-private-ip-address"
  purpose       = "VPC_PEERING"
  address       = cidrhost(cidrsubnet(var.network_cidr, 8, 2), 0)
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google.name]
}
