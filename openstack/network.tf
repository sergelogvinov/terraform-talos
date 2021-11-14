
# resource "openstack_networking_network_v2" "main" {
#   count          = length(var.regions)
#   region         = element(var.regions, count.index)
#   name           = "main"
#   admin_state_up = "true"
# }

data "openstack_networking_network_v2" "main" {
  count    = length(var.regions)
  region   = element(var.regions, count.index)
  name     = "main"
  external = false
}

resource "openstack_networking_subnet_v2" "core" {
  count      = length(var.regions)
  region     = element(var.regions, count.index)
  name       = "core"
  network_id = data.openstack_networking_network_v2.main[count.index].id
  cidr       = cidrsubnet(var.vpc_main_cidr, 8, count.index * 4)
  no_gateway = true
  allocation_pool {
    start = cidrhost(cidrsubnet(var.vpc_main_cidr, 8, count.index * 4), 11)
    end   = cidrhost(cidrsubnet(var.vpc_main_cidr, 8, count.index * 4), -7)
  }
  ip_version = 4
}

resource "openstack_networking_subnet_v2" "private" {
  count      = length(var.regions)
  region     = element(var.regions, count.index)
  name       = "private"
  network_id = data.openstack_networking_network_v2.main[count.index].id
  cidr       = cidrsubnet(var.vpc_main_cidr, 8, 1 + count.index * 4)
  allocation_pool {
    start = cidrhost(cidrsubnet(var.vpc_main_cidr, 8, 1 + count.index * 4), 11)
    end   = cidrhost(cidrsubnet(var.vpc_main_cidr, 8, 1 + count.index * 4), -7)
  }
  ip_version = 4
}

data "openstack_networking_network_v2" "external" {
  count    = length(var.regions)
  region   = element(var.regions, count.index)
  name     = "Ext-Net"
  external = true
}

resource "openstack_networking_router_v2" "gw" {
  count               = length(var.regions)
  region              = element(var.regions, count.index)
  name                = "private"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external[count.index].id
}

resource "openstack_networking_port_v2" "gw" {
  count          = length(var.regions)
  region         = element(var.regions, count.index)
  name           = "gw"
  network_id     = data.openstack_networking_network_v2.main[count.index].id
  admin_state_up = "true"
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.private[count.index].id
    ip_address = cidrhost(openstack_networking_subnet_v2.private[count.index].cidr, 1)
  }
}

resource "openstack_networking_router_interface_v2" "private" {
  count     = length(var.regions)
  region    = element(var.regions, count.index)
  router_id = openstack_networking_router_v2.gw[count.index].id
  port_id   = openstack_networking_port_v2.gw[count.index].id
}
