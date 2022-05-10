
data "openstack_networking_network_v2" "external" {
  for_each = { for idx, name in var.regions : name => idx }
  region   = each.key
  name     = var.network_name_external
  external = true
}

resource "openstack_networking_router_v2" "gw" {
  for_each            = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) }
  region              = each.key
  name                = openstack_networking_subnet_v2.private[each.key].name
  external_network_id = data.openstack_networking_network_v2.external[each.key].id
  admin_state_up      = true

  # external_fixed_ip {
  #   subnet_id  = data.openstack_networking_network_v2.external[each.key].id
  #   ip_address = [for k in openstack_networking_port_v2.gw_external[each.key].all_fixed_ips : k if length(regexall("[0-9.]+", k)) > 0][0]
  # }
}

resource "openstack_networking_port_v2" "gw_external" {
  for_each       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) == false }
  region         = each.key
  name           = "gw-${lower(each.key)}-${openstack_networking_subnet_v2.private[each.key].name}"
  network_id     = data.openstack_networking_network_v2.external[each.key].id
  admin_state_up = "true"
}

resource "openstack_networking_port_v2" "gw_public" {
  for_each       = { for idx, name in var.regions : name => idx }
  region         = each.key
  name           = "gw-${lower(each.key)}-${openstack_networking_subnet_v2.public[each.key].name}"
  network_id     = local.network_id[each.key].id
  admin_state_up = "true"
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.public[each.key].id
    ip_address = cidrhost(openstack_networking_subnet_v2.public[each.key].cidr, 1)
  }
}

resource "openstack_networking_port_v2" "gw_private" {
  for_each       = { for idx, name in var.regions : name => idx }
  region         = each.key
  name           = "gw-${lower(each.key)}-${openstack_networking_subnet_v2.private[each.key].name}"
  network_id     = local.network_id[each.key].id
  admin_state_up = "true"
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.private[each.key].id
    ip_address = cidrhost(openstack_networking_subnet_v2.private[each.key].cidr, 1)
  }
}

resource "openstack_networking_router_interface_v2" "private" {
  for_each  = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) }
  region    = each.key
  router_id = openstack_networking_router_v2.gw[each.key].id
  subnet_id = openstack_networking_subnet_v2.private[each.key].id
  port_id   = openstack_networking_port_v2.gw_private[each.key].id
}

### Soft gateway

# resource "openstack_compute_instance_v2" "gw" {
#   for_each    = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) == false }
#   region      = each.key
#   name        = "gw-${lower(each.key)}"
#   image_id    = data.openstack_images_image_v2.debian[each.key].id
#   flavor_name = "d2-2"
#   key_pair    = openstack_compute_keypair_v2.keypair[each.key].name

#   network {
#     port           = openstack_networking_port_v2.gw_external[each.key].id
#     uuid           = data.openstack_networking_network_v2.external[each.key].id
#     access_network = true
#   }
#   network {
#     port = openstack_networking_port_v2.gw[each.key].id
#   }

#   user_data = <<EOF
# #cloud-config
# apt_update: true
# apt_upgrade: true
# disable_root: false
# write_files:
#   - path: /etc/network/interfaces
#     permissions: '0644'
#     content: |
#       auto lo
#       iface lo inet loopback
#         dns-nameservers 1.1.1.1 8.8.8.8
#       iface lo inet6 loopback

#       allow-hotplug ens3
#       iface ens3 inet dhcp
#         mtu 1500
#       iface ens3 inet6 static
#         address ${[for ip in openstack_networking_port_v2.gw_external[each.key].all_fixed_ips : ip if length(regexall("[0-9a-z]+:[0-9a-z:]+", ip)) > 0][0]}
#         gateway ${cidrhost("${[for ip in openstack_networking_port_v2.gw_external[each.key].all_fixed_ips : ip if length(regexall("[0-9a-z]+:[0-9a-z:]+", ip)) > 0][0]}/56", 1)}
#         netmask 56

#       allow-hotplug ens4
#       iface ens4 inet static
#         address ${openstack_networking_port_v2.gw[each.key].all_fixed_ips[0]}
#         netmask 24
#         mtu ${local.network_id[each.key].mtu}

# runcmd:
#   - rm -f /etc/network/interfaces.d/50-cloud-init
# EOF

#   lifecycle {
#     ignore_changes = [key_pair, user_data, image_id]
#   }
# }
