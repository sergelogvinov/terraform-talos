
resource "google_compute_address" "nat" {
  name         = "${var.cluster_name}-nat-${var.region}"
  project      = var.project
  region       = var.region
  description  = "External ${var.cluster_name}-nat-${var.region} ip"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}

resource "google_compute_router" "core" {
  name    = "${var.cluster_name}-route-${var.region}"
  project = var.project
  region  = var.region
  network = google_compute_network.network.name
}

resource "google_compute_router_nat" "private" {
  name    = "${var.cluster_name}-nat-${var.region}"
  project = var.project
  region  = var.region
  router  = google_compute_router.core.name

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat.self_link]
  min_ports_per_vm       = 1024

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = data.google_compute_zones.region.names
    content {
      name                    = google_compute_subnetwork.private[subnetwork.value].name
      source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
    }
  }
}
