
resource "google_compute_region_instance_group_manager" "worker" {
  name                      = "${var.cluster_name}-worker-mig"
  project                   = var.project_id
  region                    = var.region
  distribution_policy_zones = var.zones
  base_instance_name        = "${var.cluster_name}-worker"

  version {
    instance_template = google_compute_instance_template.worker["all"].id
  }

  target_pools       = []
  target_size        = lookup(var.instances["all"], "worker_count", 0)
  wait_for_instances = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "worker" {
  for_each = { for k, v in var.instances : k => v if contains(var.zones, "${var.region}-${k}") }

  name               = "${var.cluster_name}-worker-${each.key}-mig"
  project            = var.project_id
  zone               = "${var.region}-${each.key}"
  base_instance_name = "${var.cluster_name}-worker-${each.key}"

  version {
    instance_template = google_compute_instance_template.worker[each.key].id
  }

  target_pools       = []
  target_size        = lookup(each.value, "worker_count", 0)
  wait_for_instances = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_template" "worker" {
  for_each     = var.instances
  name_prefix  = "${var.cluster_name}-worker-${each.key}-"
  project      = var.project_id
  region       = var.region
  machine_type = lookup(each.value, "worker_instance_type", "e2-standard-2")
  # min_cpu_platform = ""

  tags = concat(var.tags, ["${var.cluster_name}-infra", "${var.cluster_name}-master", "${var.cluster_name}-worker"])
  labels = {
    label = "worker"
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
    labels       = { label = "worker" }
  }

  network_interface {
    network    = var.network
    subnetwork = "core"
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
