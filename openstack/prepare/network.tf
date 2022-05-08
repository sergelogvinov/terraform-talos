
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
  network_id = data.openstack_networking_network_v2.main
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

resource "openstack_networking_subnet_route_v2" "public" {
  for_each         = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) }
  subnet_id        = openstack_networking_subnet_v2.public[each.key].id
  destination_cidr = var.network_cidr
  next_hop         = cidrhost(openstack_networking_subnet_v2.public[each.key].cidr, 1)
}

resource "openstack_networking_subnet_route_v2" "private" {
  for_each         = { for idx, name in var.regions : name => idx if try(var.capabilities[name].gateway, false) }
  subnet_id        = openstack_networking_subnet_v2.private[each.key].id
  destination_cidr = var.network_cidr
  next_hop         = openstack_networking_subnet_v2.private[each.key].gateway_ip
}
