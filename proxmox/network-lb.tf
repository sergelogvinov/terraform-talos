
locals {
  gwv4       = cidrhost(var.vpc_main_cidr, 1)
  lbv4_local = cidrhost(var.vpc_main_cidr, 10)
}
