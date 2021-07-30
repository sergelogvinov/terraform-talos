
resource "google_compute_address" "controlplane" {
  count        = lookup(var.controlplane, "count", 0)
  project      = var.project_id
  region       = var.region
  name         = "${var.cluster_name}-master-${count.index + 1}"
  description  = "Local ${var.cluster_name}-master-${count.index + 1} ip"
  address_type = "INTERNAL"
  address      = cidrhost(cidrsubnet(var.network_cidr, 8, 0), 11 + count.index)
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
  }

  source_instance_template = google_compute_instance_template.controlplane.id
  depends_on = [
    google_compute_instance_template.controlplane
  ]
}

resource "google_compute_instance_template" "controlplane" {
  name_prefix  = "${var.cluster_name}-master-"
  project      = var.project_id
  region       = var.region
  machine_type = lookup(var.controlplane, "type", "e2-standard-2")
  # min_cpu_platform = ""

  tags = concat(var.tags, ["${var.cluster_name}-infra", "${var.cluster_name}-master", "${var.cluster_name}-web"])
  labels = {
    label = "controlplane"
  }

  metadata = {
    ssh-keys = "debian:${file("~/.ssh/terraform.pub")}"
  }
  metadata_startup_script = "apt-get install -y nginx"

  disk {
    boot         = true
    auto_delete  = true
    disk_size_gb = 16
    disk_type    = "pd-balanced" // pd-ssd
    source_image = "debian-cloud/debian-10"
    labels       = { label = "controlplane" }
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
#       name           = "master-${count.index + 1}"
#       type           = count.index == 0 ? "init" : "controlplane"
#       ipv4_local     = cidrhost(hcloud_network_subnet.core.ip_range, 11 + count.index)
#       ipv4           = hcloud_server.controlplane[count.index].ipv4_address
#       ipv6           = hcloud_server.controlplane[count.index].ipv6_address
#       lbv4_local     = hcloud_load_balancer_network.api.ip
#       lbv4           = hcloud_load_balancer.api.ipv4
#       lbv6           = hcloud_load_balancer.api.ipv6
#       hcloud_network = hcloud_network.main.id
#       hcloud_token   = var.hcloud_token
#     })
#   )
#   filename        = "_cfgs/controlplane-${count.index + 1}.yaml"
#   file_permission = "0640"

#   depends_on = [hcloud_server.controlplane]
# }

# resource "null_resource" "controlplane" {
#   count = lookup(var.controlplane, "count", 0)
#   provisioner "local-exec" {
#     command = "sleep 60 && talosctl apply-config --insecure --nodes ${hcloud_server.controlplane[count.index].ipv4_address} --file _cfgs/controlplane-${count.index + 1}.yaml"
#   }
#   depends_on = [hcloud_load_balancer_target.api, local_file.controlplane]
# }
