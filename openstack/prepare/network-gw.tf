
data "openstack_networking_network_v2" "external" {
  for_each = { for idx, name in var.regions : name => idx }
  region   = each.key
  name     = var.network_name_external
  external = true
}

data "openstack_networking_subnet_ids_v2" "external_v6" {
  for_each   = { for idx, name in var.regions : name => idx }
  region     = each.key
  network_id = data.openstack_networking_network_v2.external[each.key].id
  ip_version = 6
}

# resource "openstack_networking_port_v2" "nat" {
#   for_each       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) }
#   region         = each.key
#   name           = "nat-${lower(each.key)}-${openstack_networking_subnet_v2.private[each.key].name}"
#   network_id     = data.openstack_networking_network_v2.external[each.key].id
#   admin_state_up = "true"
# }

resource "openstack_networking_router_v2" "nat" {
  for_each            = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) }
  region              = each.key
  name                = "nat-${openstack_networking_subnet_v2.private[each.key].name}"
  external_network_id = data.openstack_networking_network_v2.external[each.key].id
  admin_state_up      = true

  # external_fixed_ip {
  #   subnet_id  = data.openstack_networking_network_v2.external[each.key].id
  #   ip_address = [for ip in openstack_networking_port_v2.nat[each.key].all_fixed_ips : ip if length(split(".", ip)) > 1][0]
  # }
}

# resource "openstack_networking_port_v2" "gw_external" {
#   for_each       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) == false }
#   region         = each.key
#   name           = "gw-${lower(each.key)}-${openstack_networking_subnet_v2.private[each.key].name}"
#   network_id     = data.openstack_networking_network_v2.external[each.key].id
#   admin_state_up = "true"
# }

resource "openstack_networking_router_interface_v2" "private" {
  for_each  = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) }
  region    = each.key
  router_id = openstack_networking_router_v2.nat[each.key].id
  subnet_id = openstack_networking_subnet_v2.private[each.key].id
  # port_id = openstack_networking_port_v2.gw_private[each.key].id
}

### Soft router to peering networks

resource "openstack_networking_port_v2" "router_external" {
  for_each           = { for idx, name in var.regions : name => idx if try(var.capabilities[name].peering, false) }
  region             = each.key
  name               = "router-${lower(each.key)}-${openstack_networking_subnet_v2.private[each.key].name}"
  network_id         = data.openstack_networking_network_v2.external[each.key].id
  security_group_ids = [openstack_networking_secgroup_v2.router[each.key].id]
  admin_state_up     = "true"
}

resource "openstack_networking_port_v2" "router" {
  for_each       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].peering, false) }
  region         = each.key
  name           = "router-${lower(each.key)}-${openstack_networking_subnet_v2.private[each.key].name}"
  network_id     = local.network_id[each.key].id
  admin_state_up = "true"
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.private[each.key].id
    ip_address = cidrhost(openstack_networking_subnet_v2.private[each.key].cidr, try(var.capabilities[each.key].gateway, false) ? 2 : 1)
  }
  # fixed_ip {
  #   subnet_id  = openstack_networking_subnet_v2.private_v6[each.key].id
  #   ip_address = cidrhost(openstack_networking_subnet_v2.private_v6[each.key].cidr, 1)
  # }
}

resource "openstack_compute_instance_v2" "router" {
  for_each    = { for idx, name in var.regions : name => idx if try(var.capabilities[name].peering, false) }
  region      = each.key
  name        = "router-${lower(each.key)}"
  image_id    = data.openstack_images_image_v2.debian[each.key].id
  flavor_name = try(var.capabilities[each.key].peering_type, "d2-2")
  key_pair    = openstack_compute_keypair_v2.keypair[each.key].name

  network {
    port           = openstack_networking_port_v2.router_external[each.key].id
    uuid           = openstack_networking_port_v2.router_external[each.key].network_id
    access_network = true
  }
  network {
    port = openstack_networking_port_v2.router[each.key].id
  }

  user_data = <<EOF
#cloud-config
apt_update: true
apt_upgrade: true
disable_root: false
write_files:
  - path: /etc/network/interfaces
    permissions: '0644'
    content: |
      auto lo
      iface lo inet loopback
      iface lo inet6 loopback

      allow-hotplug ens3
      iface ens3 inet dhcp
        mtu 1500
      iface ens3 inet6 static
        address ${[for ip in openstack_networking_port_v2.router_external[each.key].all_fixed_ips : ip if length(split(":", ip)) > 1][0]}
        gateway ${cidrhost("${[for ip in openstack_networking_port_v2.router_external[each.key].all_fixed_ips : ip if length(split(":", ip)) > 1][0]}/56", 1)}
        netmask 56

      allow-hotplug ens4
      iface ens4 inet static
        address ${[for ip in openstack_networking_port_v2.router[each.key].all_fixed_ips : ip if length(split(".", ip)) > 1][0]}
        netmask 24
        mtu ${local.network_id[each.key].mtu}
        post-up ip ro add ${openstack_networking_subnet_v2.public[each.key].cidr} dev ens4
      iface ens4 inet6 static
        address ${cidrhost(openstack_networking_subnet_v2.private_v6[each.key].cidr, 1)}
        netmask 64

runcmd:
  - rm -f /etc/network/interfaces.d/50-cloud-init
  - reboot
EOF

  lifecycle {
    ignore_changes = [key_pair, user_data, image_id]
  }
}
