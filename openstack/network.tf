
data "openstack_networking_subnet_v2" "controlplane_public" {
  for_each   = { for idx, name in local.regions : name => idx }
  region     = each.key
  network_id = local.network_external[each.key].id
  ip_version = 6
}

# resource "openstack_networking_router_v2" "gw" {
#   count               = length(var.regions)
#   region              = element(var.regions, count.index)
#   name                = "private"
#   admin_state_up      = true
#   external_network_id = data.openstack_networking_network_v2.external[count.index].id
# }

# resource "openstack_networking_port_v2" "gw" {
#   count          = length(var.regions)
#   region         = element(var.regions, count.index)
#   name           = "gw"
#   network_id     = data.openstack_networking_network_v2.main[count.index].id
#   admin_state_up = "true"
#   fixed_ip {
#     subnet_id  = openstack_networking_subnet_v2.private[count.index].id
#     ip_address = cidrhost(openstack_networking_subnet_v2.private[count.index].cidr, 1)
#   }
# }

# resource "openstack_networking_router_interface_v2" "private" {
#   count     = length(var.regions)
#   region    = element(var.regions, count.index)
#   router_id = openstack_networking_router_v2.gw[count.index].id
#   port_id   = openstack_networking_port_v2.gw[count.index].id
# }
