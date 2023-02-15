
data "openstack_networking_network_v2" "main" {
  for_each = { for idx, name in var.regions : name => idx }
  region   = each.key
  name     = var.network_name
  external = false
}

# resource "openstack_networking_network_v2" "main" {
#   for_each       = { for idx, name in var.regions : name => idx }
#   region         = each.key
#   name           = var.network_name
#   admin_state_up = "true"
# }

locals {
  network_id      = data.openstack_networking_network_v2.main
  network_cidr_v6 = cidrsubnet("fd60:${replace(cidrhost(var.network_cidr, 0), ".", ":")}::/56", 0, 0)
}

resource "openstack_networking_subnet_v2" "public" {
  for_each   = { for idx, name in var.regions : name => idx }
  region     = each.key
  name       = "public"
  network_id = local.network_id[each.key].id
  cidr       = cidrsubnet(var.network_cidr, 8, (var.network_shift + each.value) * 4)
  no_gateway = true
  allocation_pool {
    start = cidrhost(cidrsubnet(var.network_cidr, 8, (var.network_shift + each.value) * 4), 128)
    end   = cidrhost(cidrsubnet(var.network_cidr, 8, (var.network_shift + each.value) * 4), -7)
  }
  ip_version      = 4
  dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}

resource "openstack_networking_subnet_v2" "private" {
  for_each   = { for idx, name in var.regions : name => idx }
  region     = each.key
  name       = "private"
  network_id = local.network_id[each.key].id
  cidr       = cidrsubnet(var.network_cidr, 8, 1 + (var.network_shift + each.value) * 4)
  allocation_pool {
    start = cidrhost(cidrsubnet(var.network_cidr, 8, 1 + (var.network_shift + each.value) * 4), 128)
    end   = cidrhost(cidrsubnet(var.network_cidr, 8, 1 + (var.network_shift + each.value) * 4), -7)
  }
  ip_version      = 4
  dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}

resource "openstack_networking_subnet_v2" "private_v6" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  name              = "private-v6"
  network_id        = local.network_id[each.key].id
  cidr              = cidrsubnet(local.network_cidr_v6, 8, 1 + 4 * (var.network_shift + each.value))
  no_gateway        = true
  ip_version        = 6
  ipv6_address_mode = "slaac" # dhcpv6-stateless dhcpv6-stateful # slaac
  # ipv6_ra_mode      = "slaac" # dhcpv6-stateless dhcpv6-stateful
  dns_nameservers = ["2001:4860:4860::8888"]
}

resource "openstack_networking_subnet_route_v2" "public_v4" {
  for_each         = { for idx, name in var.regions : name => idx if data.openstack_networking_quota_v2.quota[name].router > 0 }
  region           = each.key
  subnet_id        = openstack_networking_subnet_v2.public[each.key].id
  destination_cidr = var.network_cidr
  next_hop         = try(var.capabilities[each.key].gateway, false) ? cidrhost(openstack_networking_subnet_v2.private[each.key].cidr, 2) : cidrhost(openstack_networking_subnet_v2.private[each.key].cidr, 1)
}

resource "openstack_networking_subnet_route_v2" "private_v4" {
  for_each         = { for idx, name in var.regions : name => idx if data.openstack_networking_quota_v2.quota[name].router > 0 }
  region           = each.key
  subnet_id        = openstack_networking_subnet_v2.private[each.key].id
  destination_cidr = var.network_cidr
  next_hop         = try(var.capabilities[each.key].gateway, false) ? cidrhost(openstack_networking_subnet_v2.private[each.key].cidr, 2) : cidrhost(openstack_networking_subnet_v2.private[each.key].cidr, 1)
}

resource "openstack_networking_subnet_route_v2" "private_v6" {
  for_each         = { for idx, name in var.regions : name => idx if data.openstack_networking_quota_v2.quota[name].router > 0 }
  region           = each.key
  subnet_id        = openstack_networking_subnet_v2.private_v6[each.key].id
  destination_cidr = local.network_cidr_v6
  next_hop         = cidrhost(openstack_networking_subnet_v2.private_v6[each.key].cidr, 1)
}
