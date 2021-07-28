
resource "google_compute_address" "controlplane" {
  count        = lookup(var.controlplane, "count", 0)
  project      = var.project_id
  region       = var.region
  name         = "master-${count.index + 1}"
  description  = "Local master-${count.index + 1} ip"
  address_type = "INTERNAL"
  address      = cidrhost(cidrsubnet(var.network_cidr, 8, 0), 11 + count.index)
  subnetwork   = "core"
  purpose      = "GCE_ENDPOINT"
}

resource "google_compute_instance" "controlplane" {
  count        = lookup(var.controlplane, "count", 0)
  name         = "master-${count.index + 1}"
  machine_type = lookup(var.controlplane, "type", "e2-standard-2")
  zone         = element(var.zones, count.index)

  tags = concat(var.tags, ["${var.cluster_name}-infra", "${var.cluster_name}-master", "${var.cluster_name}-web"])

  boot_disk {
    auto_delete = true
    initialize_params {
      size  = 16
      type  = "pd-balanced" // pd-ssd
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network    = var.network
    network_ip = google_compute_address.controlplane[count.index].address
    subnetwork = "core"

    access_config {
      network_tier = "STANDARD"
    }
  }

  metadata = {
    ssh-keys = "debian:${file("~/.ssh/terraform.pub")}"
  }
  metadata_startup_script = "apt-get install -y nginx"

  lifecycle {
    ignore_changes = [
      machine_type,
      boot_disk,
    ]
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
