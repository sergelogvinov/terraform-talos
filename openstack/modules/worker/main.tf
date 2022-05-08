
resource "openstack_networking_port_v2" "worker" {
  count          = var.instance_count
  region         = var.region
  name           = "${var.instance_name}-${lower(var.region)}-${count.index + 1}"
  network_id     = var.network_internal.network_id
  admin_state_up = true

  fixed_ip {
    subnet_id  = var.network_internal.subnet_id
    ip_address = cidrhost(var.network_internal.cidr, var.instance_ip_start + count.index)
  }
}

locals {
  worker_labels = "topology.kubernetes.io/region=nova,topology.kubernetes.io/zone=${var.region},project.io/node-pool=${var.instance_name}"
}

resource "openstack_compute_instance_v2" "worker" {
  count       = var.instance_count
  region      = var.region
  name        = "${var.instance_name}-${lower(var.region)}-${count.index + 1}"
  flavor_name = var.instance_flavor
  image_id    = var.instance_image

  user_data = templatefile("${path.module}/../../templates/worker.yaml.tpl",
    merge(var.instance_params, {
      name        = "${var.instance_name}-${lower(var.region)}-${count.index + 1}"
      labels      = local.worker_labels
      iface       = try(var.network_external.name, "") == "" ? "eth0" : "eth1"
      nodeSubnets = var.network_internal.cidr
    })
  )

  dynamic "network" {
    for_each = try([var.network_external.name], [])
    content {
      name = network.value
    }
  }
  network {
    port = openstack_networking_port_v2.worker[count.index].id
  }

  lifecycle {
    ignore_changes = [flavor_name, image_id, user_data]
  }
}

resource "local_file" "controlplane" {
  count = var.instance_count

  content = templatefile("${path.module}/../../templates/worker.yaml.tpl",
    merge(var.instance_params, {
      name        = "${var.instance_name}-${lower(var.region)}-${count.index + 1}"
      labels      = local.worker_labels
      iface       = try(var.network_external.name, "") == "" ? "eth0" : "eth1"
      nodeSubnets = var.network_internal.cidr
    })
  )
  filename        = "_cfgs/${var.instance_name}-${lower(var.region)}-${count.index + 1}.yaml"
  file_permission = "0600"
}
