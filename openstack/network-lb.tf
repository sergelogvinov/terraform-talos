
resource "openstack_networking_port_v2" "vip" {
  for_each       = { for idx, name in local.regions : name => idx }
  region         = each.key
  name           = "controlplane-${lower(each.key)}-lb"
  network_id     = local.network_public[each.key].network_id
  admin_state_up = true

  port_security_enabled = false
  fixed_ip {
    subnet_id  = local.network_public[each.key].subnet_id
    ip_address = cidrhost(local.network_public[each.key].cidr, 5)
  }
}
