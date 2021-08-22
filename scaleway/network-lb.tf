
locals {
  lb_enable = lookup(var.controlplane, "type_lb", "") == "" ? false : true
}

locals {
  lbv4 = local.lb_enable ? scaleway_lb_ip.lb[0].ip_address : try(scaleway_instance_ip.controlplane[0].address, "127.0.0.1")
}

resource "scaleway_lb_ip" "lb" {
  count = local.lb_enable ? 1 : 0
  # zone    = element(var.regions, count.index)
}

resource "scaleway_lb" "lb" {
  count = local.lb_enable ? 1 : 0
  # name  = "lb"
  ip_id = scaleway_lb_ip.lb[0].id
  type  = lookup(var.controlplane, "type_lb", "")
  tags  = concat(var.tags, ["infra"])
}

resource "scaleway_lb_backend" "api" {
  count            = local.lb_enable ? 1 : 0
  lb_id            = scaleway_lb.lb[0].id
  name             = "api"
  forward_protocol = "tcp"
  forward_port     = "6443"
  server_ips       = scaleway_instance_server.controlplane[*].private_ip

  health_check_tcp {}
}

resource "scaleway_lb_frontend" "api" {
  count        = local.lb_enable ? 1 : 0
  lb_id        = scaleway_lb.lb[0].id
  backend_id   = scaleway_lb_backend.api[0].id
  name         = "api"
  inbound_port = "6443"

  acl {
    name = "Allow whitlist IPs"
    action {
      type = "allow"
    }
    match {
      ip_subnet = var.whitelist_admins
    }
  }
}
