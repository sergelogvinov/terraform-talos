
locals {
  ipv4_vip   = cidrhost(openstack_networking_subnet_v2.core[0].cidr, 10)
  lbv4_local = cidrhost(openstack_networking_subnet_v2.core[0].cidr, 10)
  lbv4       = cidrhost(openstack_networking_subnet_v2.core[0].cidr, 10)
}
