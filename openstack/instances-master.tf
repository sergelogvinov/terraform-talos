
resource "openstack_networking_port_v2" "vip" {
  count          = 1
  region         = element(var.regions, count.index)
  name           = "vip"
  network_id     = data.openstack_networking_network_v2.main[count.index].id
  admin_state_up = true

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.core[count.index].id
    ip_address = local.ipv4_vip
  }
}

resource "openstack_networking_port_v2" "controlplane" {
  count                 = length(var.regions)
  region                = element(var.regions, count.index)
  name                  = "controlplane-${count.index + 1}"
  network_id            = data.openstack_networking_network_v2.main[count.index].id
  admin_state_up        = true
  port_security_enabled = false

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.core[count.index].id
    ip_address = cidrhost(openstack_networking_subnet_v2.core[count.index].cidr, 11 + count.index)
  }
}

resource "openstack_networking_port_v2" "controlplane_public" {
  count          = length(var.regions)
  region         = element(var.regions, count.index)
  name           = "controlplane-public-${count.index + 1}"
  network_id     = data.openstack_networking_network_v2.external[count.index].id
  admin_state_up = "true"
}

data "openstack_networking_subnet_v2" "controlplane_public" {
  count      = length(var.regions)
  region     = element(var.regions, count.index)
  network_id = data.openstack_networking_network_v2.external[count.index].id
  # address_scope_id = openstack_networking_port_v2.controlplane_public[count.index].id
  ip_version = 6
}

resource "openstack_compute_instance_v2" "controlplane" {
  count       = 0
  name        = "master-${count.index + 1}"
  image_id    = openstack_images_image_v2.talos[count.index].id
  flavor_name = "d2-4"
  region      = element(var.regions, count.index)

  user_data = templatefile("${path.module}/templates/controlplane.yaml",
    merge(var.kubernetes, {
      name        = "master-${count.index + 1}"
      type        = "controlplane"
      lbv4        = local.lbv4
      ipv4_local  = openstack_networking_port_v2.controlplane[count.index].fixed_ip[0].ip_address
      ipv4_vip    = local.ipv4_vip
      ipv6        = [for k in openstack_networking_port_v2.controlplane_public[count.index].all_fixed_ips : k if length(regexall("[0-9a-z]+:[0-9a-z:]+", k)) > 0][0]
      ipv6_gw     = data.openstack_networking_subnet_v2.controlplane_public[count.index].gateway_ip
      nodeSubnets = var.vpc_main_cidr
    })
  )

  network {
    port = openstack_networking_port_v2.controlplane_public[count.index].id
  }
  network {
    port = openstack_networking_port_v2.controlplane[count.index].id
  }

  lifecycle {
    ignore_changes = [user_data, image_id]
  }
}

# resource "local_file" "controlplane" {
#   count = 1
#   content = templatefile("${path.module}/templates/controlplane.yaml",
#     merge(var.kubernetes, {
#       name        = "master-${count.index + 1}"
#       type        = "controlplane"
#       lbv4        = local.lbv4
#       ipv4_local  = openstack_networking_port_v2.controlplane[count.index].fixed_ip[0].ip_address
#       ipv4_vip    = local.ipv4_vip
#       ipv6        = [for k in openstack_networking_port_v2.controlplane_public[count.index].all_fixed_ips : k if length(regexall("[0-9a-z]+:[0-9a-z:]+", k)) > 0][0]
#       ipv6_gw     = data.openstack_networking_subnet_v2.controlplane_public[count.index].gateway_ip
#       nodeSubnets = var.vpc_main_cidr
#     })
#   )
#   filename        = "_cfgs/controlplane-${count.index + 1}.yaml"
#   file_permission = "0640"
# }
