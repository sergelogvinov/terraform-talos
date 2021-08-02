
resource "google_compute_address" "controlplane" {
  count        = max(lookup(var.controlplane, "count", 0), length(var.zones))
  project      = var.project_id
  region       = var.region
  name         = "${var.cluster_name}-master-${count.index + 1}"
  description  = "Local ${var.cluster_name}-master-${count.index + 1} ip"
  address_type = "INTERNAL"
  address      = cidrhost(cidrsubnet(var.network_cidr, 8, 0), 231 + count.index)
  subnetwork   = "core"
  purpose      = "GCE_ENDPOINT"
}

resource "google_compute_instance_from_template" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
  name  = "master-${count.index + 1}"
  project = var.project_id
  zone    = element(var.zones, count.index)

  network_interface {
    network    = var.network
    network_ip = google_compute_address.controlplane[count.index].address
    subnetwork = "core"
    access_config {
      network_tier = "STANDARD"
    }
    alias_ip_range = count.index == 0 ? [{
      ip_cidr_range = "${google_compute_address.lbv4_local.address}/32"
      subnetwork_range_name = ""
    }] : []
  }

  source_instance_template = google_compute_instance_template.controlplane.id
  depends_on = [
    google_compute_instance_template.controlplane
  ]

  lifecycle {
    ignore_changes = [
      source_instance_template,
      labels
    ]
  }
}

resource "google_compute_instance_template" "controlplane" {
  name_prefix  = "${var.cluster_name}-master-"
  project      = var.project_id
  region       = var.region
  machine_type = lookup(var.controlplane, "type", "e2-standard-2")
  # min_cpu_platform = ""

  tags = concat(var.tags, ["${var.cluster_name}-infra", "${var.cluster_name}-master"])
  labels = {
    label = "controlplane"
  }

  # metadata = {
  #   ssh-keys = "debian:${file("~/.ssh/terraform.pub")}"
  # }
  # metadata_startup_script = "apt-get install -y nginx"

  disk {
    boot              = true
    auto_delete       = true
    disk_size_gb      = 16
    disk_type         = "pd-ssd"
    resource_policies = []
    source_image      = data.google_compute_image.talos.self_link
    labels            = { label = "controlplane" }
  }

  network_interface {
    network    = var.network
    subnetwork = "core"

    access_config {
      network_tier = "STANDARD"
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  lifecycle {
    create_before_destroy = "true"
  }
}

# resource "local_file" "controlplane" {
#   count = lookup(var.controlplane, "count", 0)
#   content = templatefile("${path.module}/templates/controlplane.yaml",
#     merge(var.kubernetes, {
#       name       = "master-${count.index + 1}"
#       type       = count.index == 0 ? "init" : "controlplane"
#       ipv4_local = google_compute_address.controlplane[count.index].address
#       ipv4       = google_compute_instance_from_template.controlplane[count.index].network_interface[0].access_config[0].nat_ip
#       lbv4_local = google_compute_address.lbv4_local.address
#       lbv4       = google_compute_instance_from_template.controlplane[count.index].network_interface[0].access_config[0].nat_ip
#     })
#   )
#   filename        = "_cfgs/controlplane-${count.index + 1}.yaml"
#   file_permission = "0640"

#   depends_on = [google_compute_instance_from_template.controlplane]
# }

# resource "null_resource" "controlplane" {
#   count = lookup(var.controlplane, "count", 0)
#   provisioner "local-exec" {
#     command = "sleep 60 && talosctl apply-config --insecure --nodes ${google_compute_instance_from_template.controlplane[count.index].network_interface[0].access_config[0].nat_ip} --file _cfgs/controlplane-${count.index + 1}.yaml"
#   }
#   depends_on = [google_compute_instance_from_template.controlplane, local_file.controlplane]
# }
