
resource "google_compute_address" "lbv4_local" {
  project      = local.project
  region       = local.region
  name         = "${local.cluster_name}-controlplane-lbv4"
  description  = "Local ${local.cluster_name}-controlplane-lbv4 ip"
  address_type = "INTERNAL"
  address      = cidrhost(local.network_controlplane.ip_cidr_range, 230)
  subnetwork   = local.network_controlplane.name
  purpose      = "GCE_ENDPOINT"
}

resource "google_compute_forwarding_rule" "controlplane" {
  project               = local.project
  name                  = "${local.cluster_name}-controlplane"
  region                = local.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.controlplane.self_link
  network               = local.network_controlplane.network
  subnetwork            = local.network_controlplane.name
  ip_address            = google_compute_address.lbv4_local.address
  ports                 = ["6443"]
  ip_protocol           = "TCP"
  network_tier          = "PREMIUM"
}

resource "google_compute_region_backend_service" "controlplane" {
  project               = local.project
  name                  = "${local.cluster_name}-controlplane"
  region                = local.region
  health_checks         = [google_compute_region_health_check.controlplane.self_link]
  load_balancing_scheme = "INTERNAL"
  protocol              = "TCP"

  connection_draining_timeout_sec = 300
  session_affinity                = "NONE"

  dynamic "backend" {
    for_each = module.controlplane
    content {
      balancing_mode = "CONNECTION"
      group          = backend.value.instance_group_id
    }
  }
}

resource "google_compute_region_health_check" "controlplane" {
  name                = "${local.cluster_name}-controlplane-health-check"
  region              = local.region
  check_interval_sec  = 15
  timeout_sec         = 5
  healthy_threshold   = 1
  unhealthy_threshold = 2

  tcp_health_check {
    port = "6443"
  }
  log_config {
    enable = false
  }
}
