
resource "google_compute_firewall" "controlplane" {
  project       = var.project_id
  name          = "${var.cluster_name}-controlplane"
  network       = var.network
  description   = "Managed by terraform: Allow k8s/talos service"
  priority      = 1000
  direction     = "INGRESS"
  source_ranges = [var.network_cidr]
  target_tags   = ["${var.cluster_name}-master"]

  allow {
    protocol = "tcp"
    ports    = ["6443", "50000", "50001"]
  }
}

resource "google_compute_firewall" "controlplane_admin" {
  project       = var.project_id
  name          = "${var.cluster_name}-controlplane-admin"
  network       = var.network
  description   = "Managed by terraform: Allow admin console"
  priority      = 1001
  direction     = "INGRESS"
  source_ranges = var.whitelist_admin
  target_tags   = ["${var.cluster_name}-master"]

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "50000"]
  }
}

resource "google_compute_firewall" "controlplane_health_check" {
  project       = var.project_id
  name          = "${var.cluster_name}-controlplane-health"
  network       = var.network
  description   = "Managed by terraform: Allow health check"
  priority      = 1002
  direction     = "INGRESS"
  source_ranges = ["169.254.169.254"]
  target_tags   = ["${var.cluster_name}-master"]

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
}

resource "google_compute_firewall" "web" {
  project       = var.project_id
  name          = "${var.cluster_name}-web"
  network       = var.network
  description   = "Managed by terraform: Allow web"
  priority      = 1000
  direction     = "INGRESS"
  source_ranges = var.whitelist_web
  target_tags   = ["${var.cluster_name}-web"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "web_health_check" {
  project       = var.project_id
  name          = "${var.cluster_name}-web-health"
  network       = var.network
  description   = "Managed by terraform: Allow web health check"
  priority      = 1001
  direction     = "INGRESS"
  source_ranges = ["169.254.169.254"]
  target_tags   = ["${var.cluster_name}-web"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}
