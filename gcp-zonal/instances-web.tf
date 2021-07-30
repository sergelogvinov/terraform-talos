
resource "google_compute_instance_group_manager" "web" {
  for_each = var.instances

  name               = "${var.cluster_name}-web-${each.key}-mig"
  project            = var.project_id
  zone               = "${var.region}-${each.key}"
  base_instance_name = "${var.cluster_name}-web-${each.key}"

  version {
    instance_template = google_compute_instance_template.web[each.key].id
  }

  named_port {
    name = "http"
    port = 80
  }
  named_port {
    name = "https"
    port = 443
  }

  # target_pools       = [google_compute_target_pool.web.self_link]
  target_size        = lookup(each.value, "web_count", 0)
  wait_for_instances = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_template" "web" {
  for_each     = var.instances
  name_prefix  = "${var.cluster_name}-web-${each.key}-"
  project      = var.project_id
  region       = var.region
  machine_type = lookup(each.value, "web_instance_type", "e2-standard-2")
  # min_cpu_platform = ""

  tags = concat(var.tags, ["${var.cluster_name}-infra", "${var.cluster_name}-master", "${var.cluster_name}-web"])
  labels = {
    label = "web"
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
    labels       = { label = "web" }
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

# module "web" {
#   source = "./modules/worker"

#   for_each = var.instances
#   location = each.key
#   labels   = merge(var.tags, { label = "web" })
#   network  = hcloud_network.main.id
#   subnet   = hcloud_network_subnet.core.ip_range

#   vm_name           = "web-${each.key}-"
#   vm_items          = lookup(each.value, "web_count", 0)
#   vm_type           = lookup(each.value, "web_instance_type", "cx11")
#   vm_image          = data.hcloud_image.talos.id
#   vm_ip_start       = (3 + index(var.regions, each.key)) * 10
#   vm_security_group = [hcloud_firewall.web.id]

#   vm_params = merge(var.kubernetes, {
#     lbv4 = hcloud_load_balancer_network.api.ip
#   })
# }
