
# resource "openstack_networking_port_v2" "web" {
#   for_each       = { for idx, name in local.regions : name => idx }
#   region         = each.key
#   name           = "web-${lower(each.key)}-${each.value + 1}"
#   network_id     = local.network[each.key].id
#   admin_state_up = true

#   fixed_ip {
#     subnet_id  = local.network_public[each.key].id
#     ip_address = cidrhost(local.network_public[each.key].cidr, 21 + each.value)
#   }
# }

# locals {
#   web_labels = "project.io/node-pool=web"
# }

# # resource "openstack_compute_instance_v2" "web" {
# #   for_each = { for idx, name in local.regions : name => idx }
# #   region   = each.key

# #   name        = "web-${lower(each.key)}-${each.value + 1}"
# #   flavor_name = "d2-2"
# #   image_id    = data.openstack_images_image_v2.talos[each.key].id
# #   key_pair    = data.openstack_compute_keypair_v2.terraform[each.key].name

# #   user_data = templatefile("${path.module}/templates/worker.yaml.tpl",
# #     merge(var.kubernetes, {
# #       name        = "web-${lower(each.key)}-${each.value + 1}"
# #       lbv4        = openstack_networking_port_v2.vip[each.key].fixed_ip[0].ip_address
# #       nodeSubnets = local.network_public[each.key].cidr
# #       labels      = local.web_labels
# #     })
# #   )

# #   network {
# #     name = local.network_external[each.key].name
# #   }
# #   network {
# #     port = openstack_networking_port_v2.web[each.key].id
# #   }

# #   lifecycle {
# #     ignore_changes = [flavor_name, image_id, user_data]
# #   }
# # }

# resource "local_file" "web" {
#   for_each = { for idx, name in local.regions : name => idx }

#   content = templatefile("${path.module}/templates/worker.yaml.tpl",
#     merge(var.kubernetes, {
#       name        = "web-${lower(each.key)}-${each.value + 1}"
#       lbv4        = openstack_networking_port_v2.vip[each.key].fixed_ip[0].ip_address
#       nodeSubnets = local.network_public[each.key].cidr
#       labels      = local.web_labels
#     })
#   )
#   filename        = "_cfgs/web-${lower(each.key)}-${each.value + 1}.yaml"
#   file_permission = "0600"
# }
