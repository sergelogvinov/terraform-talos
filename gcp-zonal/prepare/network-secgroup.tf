
resource "google_compute_firewall" "common" {
  for_each      = toset(var.network_cidr)
  project       = var.project
  name          = "${var.cluster_name}-common-v${length(split(".", each.value)) > 1 ? "4" : "6"}"
  network       = var.network_name
  description   = "Managed by terraform: Allow common traffic"
  priority      = 900
  direction     = "INGRESS"
  source_ranges = [each.value]
  target_tags   = ["${var.cluster_name}-common"]

  allow {
    protocol = length(split(".", each.value)) > 1 ? "icmp" : "58" # ipv6-icmp
  }

  allow {
    protocol = "tcp"
    ports    = ["4240", "10250", "50000", "50001"]
  }

  allow {
    protocol = "udp"
    ports    = ["8472"]
  }

  depends_on = [google_compute_network.network]
}


resource "google_compute_firewall" "dhcp" {
  project       = var.project
  name          = "${var.cluster_name}-dhcp-v6"
  network       = var.network_name
  description   = "Managed by terraform: Allow dhcp traffic"
  priority      = 910
  direction     = "INGRESS"
  source_ranges = ["fe80::/10"]
  target_tags   = ["${var.cluster_name}-common"]

  allow {
    protocol = "udp"
  }

  depends_on = [google_compute_network.network]
}

resource "google_compute_firewall" "common_health_check" {
  project       = var.project
  name          = "${var.cluster_name}-common-health"
  network       = var.network_name
  description   = "Managed by terraform: Allow common health check"
  priority      = 950
  direction     = "INGRESS"
  source_ranges = ["169.254.169.254", "35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = ["${var.cluster_name}-web", "${var.cluster_name}-worker"]

  allow {
    protocol = "tcp"
    ports    = ["50000"]
  }

  depends_on = [google_compute_network.network]
}

resource "google_compute_firewall" "controlplane" {
  project       = var.project
  name          = "${var.cluster_name}-controlplane"
  network       = var.network_name
  description   = "Managed by terraform: Allow controlplane services"
  priority      = 1000
  direction     = "INGRESS"
  source_ranges = [var.network_cidr[0]]
  target_tags   = ["${var.cluster_name}-controlplane"]

  allow {
    protocol = "tcp"
    ports    = ["2379", "2380", "6443", ]
  }

  depends_on = [google_compute_network.network]
}

resource "google_compute_firewall" "controlplane_admin" {
  project       = var.project
  name          = "${var.cluster_name}-controlplane-admin"
  network       = var.network_name
  description   = "Managed by terraform: Allow admin console"
  priority      = 1001
  direction     = "INGRESS"
  source_ranges = var.whitelist_admin
  target_tags   = ["${var.cluster_name}-controlplane"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["6443", "50000"]
  }

  depends_on = [google_compute_network.network]
}

resource "google_compute_firewall" "controlplane_health_check" {
  project       = var.project
  name          = "${var.cluster_name}-controlplane-health"
  network       = var.network_name
  description   = "Managed by terraform: Allow health check"
  priority      = 1100
  direction     = "INGRESS"
  source_ranges = ["169.254.169.254", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = ["${var.cluster_name}-controlplane"]

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  depends_on = [google_compute_network.network]
}

# resource "google_compute_firewall" "web" {
#   project       = var.project
#   name          = "${var.cluster_name}-web"
#   network       = var.network_name
#   description   = "Managed by terraform: Allow web"
#   priority      = 1000
#   direction     = "INGRESS"
#   source_ranges = var.whitelist_web
#   target_tags   = ["${var.cluster_name}-web"]

#   allow {
#     protocol = "tcp"
#     ports    = ["80", "443"]
#   }
# }

# resource "google_compute_firewall" "web_admin" {
#   project       = var.project
#   name          = "${var.cluster_name}-web-admin"
#   network       = var.network_name
#   description   = "Managed by terraform: Allow admin console"
#   priority      = 1010
#   direction     = "INGRESS"
#   source_ranges = var.whitelist_admin
#   target_tags   = ["${var.cluster_name}-web"]

#   allow {
#     protocol = "tcp"
#     ports    = ["80", "443"]
#   }
# }

# resource "google_compute_firewall" "web_health_check" {
#   project       = var.project
#   name          = "${var.cluster_name}-web-health"
#   network       = var.network_name
#   description   = "Managed by terraform: Allow web health check"
#   priority      = 1100
#   direction     = "INGRESS"
#   source_ranges = ["169.254.169.254", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
#   target_tags   = ["${var.cluster_name}-web"]

#   allow {
#     protocol = "tcp"
#     ports    = ["80"]
#   }
# }
