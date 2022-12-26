
resource "google_compute_address" "local" {
  count        = max(lookup(var.controlplane, "count", 0), 3)
  project      = var.project
  region       = var.region
  name         = "${var.name}-${count.index + 1}"
  description  = "Local ${var.name}-${count.index + 1} ip"
  address_type = "INTERNAL"
  address      = cidrhost(var.network_cidr, count.index)
  subnetwork   = var.subnetwork
  purpose      = "GCE_ENDPOINT"
}

resource "google_compute_instance_from_template" "controlplane" {
  count        = lookup(var.controlplane, "count", 0)
  name         = "controlplane-${var.zone}-${count.index + 1}"
  project      = var.project
  zone         = var.zone
  machine_type = lookup(var.controlplane, "type", "e2-medium")

  can_ip_forward = true
  network_interface {
    network    = var.network.network
    network_ip = google_compute_address.local[count.index].address
    subnetwork = var.subnetwork
    stack_type = "IPV4_IPV6"
    access_config {
      network_tier = "STANDARD"
    }
  }

  source_instance_template = var.instance_template

  lifecycle {
    ignore_changes = [
      attached_disk,
      machine_type,
      source_instance_template,
      metadata,
      labels
    ]
  }
}

resource "google_compute_instance_group" "controlplane" {
  project = var.project
  name    = "${var.cluster_name}-controlplane-${var.zone}"
  zone    = var.zone
  network = var.network.network

  instances = google_compute_instance_from_template.controlplane[*].self_link

  named_port {
    name = "https"
    port = "6443"
  }

  depends_on = [google_compute_instance_from_template.controlplane]
}

resource "local_sensitive_file" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
  content = templatefile("templates/controlplane.yaml",
    merge(var.kubernetes, {
      name       = "controlplane-${var.zone}-${count.index + 1}"
      ipv4       = google_compute_instance_from_template.controlplane[count.index].network_interface[0].access_config[0].nat_ip
      ipv4_local = google_compute_address.local[count.index].address
    })
  )
  filename        = "_cfgs/controlplane-${var.zone}-${count.index + 1}.yaml"
  file_permission = "0600"

  depends_on = [google_compute_instance_from_template.controlplane]
}

resource "null_resource" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
  provisioner "local-exec" {
    command = "sleep 60 && talosctl apply-config --insecure --nodes ${google_compute_instance_from_template.controlplane[count.index].network_interface[0].access_config[0].nat_ip} --file ${local_sensitive_file.controlplane[count.index].filename}"
  }

  depends_on = [google_compute_instance_from_template.controlplane, local_sensitive_file.controlplane]
}
