
# resource "google_compute_forwarding_rule" "controlplane" {
#   project               = var.project_id
#   name                  = "${var.cluster_name}-controlplane"
#   region                = var.region
#   target                = google_compute_target_pool.controlplane.self_link
#   load_balancing_scheme = "EXTERNAL"
#   port_range            = "80-443"
#   ip_protocol           = "TCP"
#   network_tier          = "STANDARD"
# }

# resource "google_compute_target_pool" "controlplane" {
#   project = var.project_id
#   name    = "${var.cluster_name}-controlplane-pool"
#   region  = var.region

#   instances     = google_compute_instance.controlplane[*].self_link
#   health_checks = [google_compute_http_health_check.controlplane.id]
# }

# resource "google_compute_http_health_check" "controlplane" {
#   name               = "${var.cluster_name}-controlplane-pool"
#   check_interval_sec = 15
#   timeout_sec        = 1
#   request_path       = "/"
# }
