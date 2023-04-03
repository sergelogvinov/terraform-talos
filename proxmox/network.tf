
locals {
  zones   = [for k, v in var.instances : k]
  subnets = { for inx, zone in local.zones : zone => cidrsubnet(var.vpc_main_cidr, 5, var.network_shift + inx) }
}
