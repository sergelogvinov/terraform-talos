
resource "openstack_networking_port_v2" "vip" {
  count          = 1
  region         = element(var.regions, count.index)
  name           = "vip"
  network_id     = data.openstack_networking_network_v2.main[count.index].id
  admin_state_up = "true"

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.core[count.index].id
    ip_address = cidrhost(openstack_networking_subnet_v2.core[count.index].cidr, 10)
  }
}

resource "openstack_networking_port_v2" "api" {
  count          = length(var.regions)
  region         = element(var.regions, count.index)
  name           = "master-${count.index + 1}"
  network_id     = data.openstack_networking_network_v2.main[count.index].id
  admin_state_up = "true"

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.core[count.index].id
    ip_address = cidrhost(openstack_networking_subnet_v2.core[count.index].cidr, 11 + count.index)
  }
}

# resource "openstack_compute_instance_v2" "api" {
#   count       = 1
#   name        = "master-${count.index + 1}"
#   image_id    = openstack_images_image_v2.talos[count.index].id
#   flavor_name = "s1-2"
#   region      = element(var.regions, count.index)
#   key_pair    = openstack_compute_keypair_v2.keypair[count.index].name
#   user_data   = file("_cfgs/talos.yaml")

#   network {
#     name           = data.openstack_networking_network_v2.external[count.index].name
#     access_network = true
#   }
#   network {
#     port = openstack_networking_port_v2.api[count.index].id
#     # name = data.openstack_networking_network_v2.main[count.index].name
#   }

#   lifecycle {
#     ignore_changes = [user_data, image_id]
#   }
# }


# resource "openstack_compute_instance_v2" "gw" {
#   count       = 1
#   name        = "gw-ovh-${count.index + 1}"
#   image_id    = data.openstack_images_image_v2.debian[count.index].id
#   flavor_name = "s1-2"
#   region      = element(var.regions, count.index)
#   key_pair    = openstack_compute_keypair_v2.keypair[count.index].name

#   network {
#     name           = data.openstack_networking_network_v2.external[count.index].name
#     access_network = true
#   }

#   lifecycle {
#     ignore_changes = [user_data, image_name, image_id]
#   }
# }
