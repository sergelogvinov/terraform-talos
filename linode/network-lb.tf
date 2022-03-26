
locals {
  lb_enable = lookup(var.controlplane, "type_lb", "") == "" ? false : true

  lbv4 = local.lb_enable ? "127.0.0.1" : linode_instance.controlplane[0].ip_address
}
