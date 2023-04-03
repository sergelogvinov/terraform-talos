
locals {
  gwv4     = cidrhost(var.vpc_main_cidr, 1)
  ipv4_vip = cidrhost(var.vpc_main_cidr, 10)
}
