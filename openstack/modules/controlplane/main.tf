
resource "openstack_networking_port_v2" "controlplane" {
  count          = var.instance_count
  region         = var.region
  name           = "controlplane-${lower(var.region)}-${count.index + 1}"
  network_id     = var.network_internal.network_id
  admin_state_up = true

  fixed_ip {
    subnet_id  = var.network_internal.subnet_id
    ip_address = cidrhost(var.network_internal.cidr, var.instance_ip_start + count.index)
  }

  lifecycle {
    ignore_changes = [port_security_enabled]
  }
}

resource "openstack_networking_port_v2" "controlplane_public" {
  count              = var.instance_count
  region             = var.region
  name               = "controlplane-${lower(var.region)}-${count.index + 1}"
  network_id         = var.network_external.id
  admin_state_up     = true
  security_group_ids = var.instance_secgroups
}

resource "openstack_compute_instance_v2" "controlplane" {
  count       = var.instance_count
  region      = var.region
  name        = "controlplane-${lower(var.region)}-${count.index + 1}"
  flavor_name = var.instance_flavor
  tags        = var.instance_tags
  image_id    = var.instance_image

  scheduler_hints {
    group = var.instance_servergroup
  }

  stop_before_destroy = true

  network {
    port = openstack_networking_port_v2.controlplane_public[count.index].id
  }
  network {
    port = openstack_networking_port_v2.controlplane[count.index].id
  }

  lifecycle {
    ignore_changes = [flavor_name, image_id, scheduler_hints, user_data]
  }
}

locals {
  ipv4_local     = var.instance_count > 0 ? [for ip in try(openstack_networking_port_v2.controlplane_public[0].all_fixed_ips, []) : ip if length(split(".", ip)) > 1][0] : ""
  ipv4_local_vip = var.instance_count > 0 ? cidrhost(var.network_internal.cidr, 5) : ""

  controlplane_labels = "project.io/cloudprovider-type=openstack,topology.kubernetes.io/region=${var.region},topology.kubernetes.io/zone=nova"
}

resource "local_file" "controlplane" {
  count = var.instance_count

  content = templatefile("${path.module}/../../templates/controlplane.yaml",
    merge(var.instance_params, {
      name   = "controlplane-${lower(var.region)}-${count.index + 1}"
      type   = "controlplane"
      labels = local.controlplane_labels

      ipv4_local     = [for k in openstack_networking_port_v2.controlplane[count.index].all_fixed_ips : k if length(regexall("[0-9]+.[0-9.]+", k)) > 0][0]
      ipv4_local_vip = local.ipv4_local_vip

      ipv4 = [for k in openstack_networking_port_v2.controlplane_public[count.index].all_fixed_ips : k if length(regexall("[0-9]+.[0-9.]+", k)) > 0][0]
      ipv6 = [for k in openstack_networking_port_v2.controlplane_public[count.index].all_fixed_ips : k if length(regexall("[0-9a-z]+:[0-9a-z:]+", k)) > 0][0]

      nodeSubnets = split(",", var.network_internal.cidr)
    })
  )
  filename        = "_cfgs/controlplane-${lower(var.region)}-${count.index + 1}.yaml"
  file_permission = "0600"
}
