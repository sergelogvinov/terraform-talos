
# resource "google_compute_address" "nat" {
#   project      = var.project_id
#   region       = var.region
#   name         = "${var.cluster_name}-nat"
#   description  = "External ${var.cluster_name}-nat ip"
#   address_type = "EXTERNAL"
#   network_tier = "PREMIUM"
# }

# resource "google_compute_router" "core" {
#   name    = "${var.cluster_name}-route"
#   region  = var.region
#   network = var.network
# }

# resource "google_compute_router_nat" "core" {
#   name    = "${var.cluster_name}-nat"
#   project = var.project_id
#   region  = var.region
#   router  = google_compute_router.core.name

#   nat_ip_allocate_option = "MANUAL_ONLY"
#   nat_ips                = [google_compute_address.nat.self_link]

#   source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
#   subnetwork {
#     name                    = "core"
#     source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
#   }
# }
