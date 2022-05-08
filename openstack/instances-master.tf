
module "controlplane" {
  source          = "./modules/controlplane"
  for_each        = { for idx, name in local.regions : name => idx }
  region          = each.key
  instance_count  = lookup(try(var.controlplane[each.key], {}), "count", 0)
  instance_flavor = lookup(try(var.controlplane[each.key], {}), "instance_type", "d2-2")
  instance_image  = data.openstack_images_image_v2.talos[each.key].id
  instance_params = merge(var.kubernetes, {
    ipv4_local_network = local.network[each.key].cidr
    ipv4_local_gw      = local.network_public[each.key].gateway
    lbv4               = local.lbv4
  })

  network_internal = local.network_public[each.key]
  network_external = local.network_external[each.key]
}

# resource "local_file" "controlplane" {
#   for_each = { for idx, name in local.regions : name => idx }

#   content = templatefile("${path.module}/templates/controlplane.yaml",
#     merge(var.kubernetes, {
#       name = "controlplane-${lower(each.key)}-${each.value + 1}"
#       type = "controlplane"

#       ipv4_local         = [for k in openstack_networking_port_v2.controlplane[each.key].all_fixed_ips : k if length(regexall("[0-9]+.[0-9.]+", k)) > 0][0]
#       ipv4_local_vip     = openstack_networking_port_v2.vip[each.key].fixed_ip[0].ip_address
#       ipv4_local_mtu     = local.network_public[each.key].mtu
#       ipv4_local_gw      = local.network_public[each.key].gateway
#       ipv4_local_network = local.network[each.key].cidr

#       lbv4    = local.lbv4
#       ipv4    = [for k in openstack_networking_port_v2.controlplane_public[each.key].all_fixed_ips : k if length(regexall("[0-9]+.[0-9.]+", k)) > 0][0]
#       ipv6    = [for k in openstack_networking_port_v2.controlplane_public[each.key].all_fixed_ips : k if length(regexall("[0-9a-z]+:[0-9a-z:]+", k)) > 0][0]
#       ipv6_gw = data.openstack_networking_subnet_v2.controlplane_public[each.key].gateway_ip

#       nodeSubnets = local.network_public[each.key].cidr
#     })
#   )
#   filename        = "_cfgs/controlplane-${lower(each.key)}-${each.value + 1}.yaml"
#   file_permission = "0600"
# }
