
resource "openstack_networking_port_v2" "worker" {
  count          = var.instance_count
  region         = var.region
  name           = "${var.instance_name}-${lower(var.region)}-${count.index + 1}"
  network_id     = var.network_internal.network_id
  admin_state_up = true

  # port_security_enabled = len(var.instance_secgroups) > 0
  # security_group_ids    = var.instance_secgroups

  fixed_ip {
    subnet_id  = var.network_internal.subnet_id
    ip_address = cidrhost(var.network_internal.cidr, var.instance_ip_start + count.index)
  }
}

resource "openstack_networking_port_v2" "worker_public" {
  count              = length(try(var.network_external, {})) == 0 ? 0 : var.instance_count
  region             = var.region
  name               = "${var.instance_name}-${lower(var.region)}-${count.index + 1}"
  network_id         = var.network_external.id
  admin_state_up     = true
  security_group_ids = var.instance_secgroups

  dynamic "fixed_ip" {
    for_each = try([var.network_external.subnet], [])
    content {
      subnet_id = fixed_ip.value
    }
  }
}

locals {
  worker_labels = "topology.kubernetes.io/region=${var.region},topology.kubernetes.io/zone=nova,project.io/node-pool=${var.instance_name}"
}

resource "openstack_compute_instance_v2" "worker" {
  count       = var.instance_count
  region      = var.region
  name        = "${var.instance_name}-${lower(var.region)}-${count.index + 1}"
  flavor_name = var.instance_flavor
  # tags        = var.instance_tags
  image_id = var.instance_image

  scheduler_hints {
    group = var.instance_servergroup
  }

  stop_before_destroy = true

  user_data = templatefile("${path.module}/../../templates/worker.yaml.tpl",
    merge(var.instance_params, {
      name        = "${var.instance_name}-${lower(var.region)}-${count.index + 1}"
      labels      = local.worker_labels
      iface       = length(try(var.network_external, {})) == 0 ? "eth0" : "eth1"
      nodeSubnets = var.network_internal.cidr
    })
  )

  dynamic "network" {
    for_each = try([openstack_networking_port_v2.worker_public[count.index]], [])
    content {
      port = network.value.id
    }
  }
  network {
    port = openstack_networking_port_v2.worker[count.index].id
  }

  lifecycle {
    ignore_changes = [flavor_name, image_id, user_data]
  }
}

resource "local_file" "worker" {
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
