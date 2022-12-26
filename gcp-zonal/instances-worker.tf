
resource "google_compute_instance_group_manager" "worker" {
  for_each = { for k, v in var.instances : k => v if k != "all" }

  name               = "${local.cluster_name}-worker-${each.key}-mig"
  description        = "${local.cluster_name}-worker terraform group"
  project            = local.project
  zone               = each.key
  base_instance_name = "worker-${each.key}"

  version {
    instance_template = google_compute_instance_template.worker[each.key].id
  }
  update_policy {
    type                  = "OPPORTUNISTIC"
    minimal_action        = "RESTART"
    max_surge_fixed       = 1
    max_unavailable_fixed = 1
    replacement_method    = "SUBSTITUTE"
  }
  # auto_healing_policies {
  #   health_check      = google_compute_health_check.instance.id
  #   initial_delay_sec = 300
  # }

  target_pools       = []
  target_size        = lookup(each.value, "worker_count", 0)
  wait_for_instances = false

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      base_instance_name,
      target_size,
    ]
  }
}

locals {
  worker_labels = "cloud.google.com/gke-boot-disk=pd-balanced,project.io/node-pool=worker"
}

resource "google_compute_instance_template" "worker" {
  for_each = { for k, v in var.instances : k => v if k != "all" }

  name_prefix  = "${local.cluster_name}-worker-${each.key}-"
  description  = "${local.cluster_name}-worker terraform template"
  project      = local.project
  region       = local.region
  machine_type = lookup(each.value, "worker_type", "e2-standard-2")

  tags = concat(var.tags, ["${local.cluster_name}-common", "${local.cluster_name}-worker"])
  labels = {
    label = "${local.cluster_name}-worker"
  }

  metadata = {
    cluster-name     = local.cluster_name
    cluster-location = local.region
    kube-labels      = local.worker_labels
    kube-env         = "AUTOSCALER_ENV_VARS: node_labels=${local.worker_labels};os=linux;os_distribution=cos"

    user-data = templatefile("${path.module}/templates/worker.yaml.tpl",
      merge(var.kubernetes, {
        lbv4        = google_compute_address.lbv4_local.address
        nodeSubnets = each.key == "all" ? local.network_controlplane.ip_cidr_range : local.networks[each.key].ip_cidr_range
        labels      = local.worker_labels
      })
    )
  }

  disk {
    boot              = true
    auto_delete       = true
    disk_size_gb      = 64
    disk_type         = "pd-balanced"
    resource_policies = []
    source_image      = data.google_compute_image.talos.self_link
    labels            = { label = "${local.cluster_name}-worker" }
  }

  can_ip_forward = true
  network_interface {
    network    = local.network_controlplane.network
    subnetwork = each.key == "all" ? local.network_controlplane.name : local.networks[each.key].self_link
    stack_type = "IPV4_IPV6"
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
