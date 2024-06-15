
locals {
  zones   = [for k, v in var.instances : k]
  subnets = { for inx, zone in local.zones : zone => cidrsubnet(var.vpc_main_cidr[0], 4, var.network_shift + inx - 1) if zone != "all" }

  gwv4 = cidrhost(var.vpc_main_cidr[0], -3)
  lbv4 = cidrhost(var.vpc_main_cidr[0], 10)
}
