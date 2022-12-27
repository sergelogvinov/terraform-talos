
locals {
  contolplane_labels = "cloud.google.com/gke-boot-disk=pd-ssd"
}

module "controlplane" {
  source = "./modules/controlplane"

  for_each     = toset(local.zones)
  name         = "${local.cluster_name}-controlplane-${each.value}"
  project      = local.project
  region       = local.region
  zone         = each.value
  cluster_name = local.cluster_name

  kubernetes = merge(var.kubernetes, {
    lbv4_local  = google_compute_address.lbv4_local.address
    nodeSubnets = local.network_controlplane.ip_cidr_range
    region      = local.region
    zone        = each.key
    project     = local.project
    network     = local.network
  })
  controlplane      = try(var.controlplane[each.key], {})
  network           = local.network_controlplane
  subnetwork        = local.network_controlplane.name
  network_cidr      = cidrsubnet(local.network_controlplane.ip_cidr_range, 6, 1 + index(local.zones, each.value))
  instance_template = google_compute_instance_template.controlplane.id
}

resource "google_compute_instance_template" "controlplane" {
  name_prefix  = "${local.cluster_name}-controlplane-"
  project      = local.project
  region       = local.region
  machine_type = "e2-medium"

  tags = concat(var.tags, ["${local.cluster_name}-common", "${local.cluster_name}-controlplane"])
  labels = {
    label = "controlplane"
  }

  metadata = {
    cluster-name     = local.cluster_name
    cluster-location = local.region
    kube-labels      = local.contolplane_labels
  }

  disk {
    boot              = true
    auto_delete       = true
    disk_size_gb      = 30
    disk_type         = "pd-ssd"
    resource_policies = []
    source_image      = data.google_compute_image.talos.self_link
    labels            = { label = "${local.cluster_name}-controlplane" }
  }

  network_interface {
    network    = local.network_controlplane.network
    subnetwork = local.network_controlplane.name
    stack_type = "IPV4_IPV6"
    access_config {
      network_tier = "STANDARD"
    }
    ipv6_access_config {
      network_tier = local.network_controlplane.ipv6_access_type == "EXTERNAL" ? "PREMIUM" : "STANDARD"
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

  service_account {
    email  = google_service_account.controlplane.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = "true"
  }
}
