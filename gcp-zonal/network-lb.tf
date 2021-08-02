
# resource "google_compute_address" "api" {
#   project      = var.project_id
#   region       = var.region
#   name         = "${var.cluster_name}-controlplane"
#   description  = "External ${var.cluster_name}-controlplane lb ip"
#   address_type = "EXTERNAL"
#   network_tier = "STANDARD"
# }

resource "google_compute_address" "lbv4_local" {
  project      = var.project_id
  region       = var.region
  name         = "${var.cluster_name}-master-lbv4"
  description  = "Local ${var.cluster_name}-master-lbv4 ip"
  address_type = "INTERNAL"
  address      = cidrhost(cidrsubnet(var.network_cidr, 8, 0), 230)
  subnetwork   = "core"
  purpose      = "GCE_ENDPOINT"
}

# resource "google_compute_forwarding_rule" "controlplane" {
#   project               = var.project_id
#   name                  = "${var.cluster_name}-controlplane"
#   region                = var.region
#   load_balancing_scheme = "INTERNAL"
#   backend_service       = google_compute_region_backend_service.controlplane.self_link
#   ip_address            = google_compute_address.lbv4_local.address
#   ports                 = ["6443","50000"]
#   ip_protocol           = "TCP"
#   network_tier          = "STANDARD"
# }

# resource "google_compute_region_backend_service" "controlplane" {
#   name                  = "${var.cluster_name}-controlplane"
#   region                = var.region
#   health_checks         = [google_compute_region_health_check.controlplane.id]
#   load_balancing_scheme = "INTERNAL"
#   protocol              = "TCP"
#   project               = var.project_id

#   dynamic "backend" {
#     for_each = google_compute_instance_group.controlplane
#     content {
#       group = backend.value.id
#     }
#   }
# }

# resource "google_compute_region_health_check" "controlplane" {
#   name                = "${var.cluster_name}-controlplane-health-check"
#   region              = var.region
#   check_interval_sec  = 15
#   timeout_sec         = 5
#   healthy_threshold   = 1
#   unhealthy_threshold = 2

#   https_health_check {
#     port         = "6443"
#     request_path = "/readyz"
#   }
# }

# resource "google_compute_instance_group" "controlplane" {
#   count   = lookup(var.controlplane, "count", 0)
#   project = var.project_id
#   name    = "${var.cluster_name}-controlplane-${element(var.zones, count.index)}"
#   zone    = element(var.zones, count.index)

#   instances = [
#     google_compute_instance_from_template.controlplane[count.index].id,
#   ]

#   named_port {
#     name = "talos"
#     port = "50000"
#   }

#   named_port {
#     name = "https"
#     port = "6443"
#   }
# }

# resource "google_compute_forwarding_rule" "web" {
#   project               = var.project_id
#   name                  = "${var.cluster_name}-web"
#   region                = var.region
#   load_balancing_scheme = "EXTERNAL"
#   backend_service       = google_compute_region_backend_service.web.self_link
#   ip_address            = google_compute_address.api.address
#   ports                 = ["80","443"]
#   ip_protocol           = "TCP"
#   network_tier          = "STANDARD"
# }

# resource "google_compute_region_backend_service" "web" {
#   name                  = "${var.cluster_name}-web"
#   region                = var.region
#   health_checks         = [google_compute_region_health_check.web.id]
#   load_balancing_scheme = "EXTERNAL"
#   protocol              = "TCP"
#   project               = var.project_id

#   backend {
#     group = google_compute_region_instance_group_manager.web.instance_group
#   }

#   dynamic "backend" {
#     for_each = google_compute_instance_group_manager.web
#     content {
#       group = backend.value.instance_group
#     }
#   }
# }

# resource "google_compute_region_health_check" "web" {
#   name                = "${var.cluster_name}-web-health-check"
#   region              = var.region
#   check_interval_sec  = 15
#   timeout_sec         = 5
#   healthy_threshold   = 1
#   unhealthy_threshold = 2

#   http_health_check {
#     port = "80"
#     # request_path = "/healthz"
#     request_path = "/"
#   }
# }
