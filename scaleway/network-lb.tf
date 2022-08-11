
locals {
  lb_enable = lookup(var.controlplane, "type_lb", "") == "" ? false : true

  ipv4_vip = cidrhost(local.main_subnet, 5)
  lbv4     = local.lb_enable ? scaleway_lb_ip.lb[0].ip_address : try(scaleway_vpc_public_gateway_ip.main.address, "127.0.0.1")
}

resource "scaleway_lb_ip" "lb" {
  count = local.lb_enable ? 1 : 0
}

resource "scaleway_lb" "lb" {
  count = local.lb_enable ? 1 : 0
  name  = "controlplane"
  ip_id = scaleway_lb_ip.lb[0].id
  type  = lookup(var.controlplane, "type_lb", "LB-S")
  tags  = concat(var.tags, ["infra"])

  private_network {
    private_network_id = scaleway_vpc_private_network.main.id
    static_config      = [cidrhost(local.main_subnet, 3), cidrhost(local.main_subnet, 4)]
  }
}

resource "scaleway_lb_backend" "api" {
  count            = local.lb_enable ? 1 : 0
  lb_id            = scaleway_lb.lb[0].id
  name             = "api"
  forward_protocol = "tcp"
  forward_port     = "6443"
  server_ips       = [for k in range(0, lookup(var.controlplane, "count", 0)) : cidrhost(local.main_subnet, 11 + k)]

  health_check_timeout = "5s"
  health_check_delay   = "30s"
  health_check_https {
    uri  = "/readyz"
    code = 401
  }
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

resource "scaleway_lb_backend" "web" {
  count            = local.lb_enable ? 1 : 0
  lb_id            = scaleway_lb.lb[0].id
  name             = "web"
  forward_protocol = "tcp"
  forward_port     = "80"
  server_ips       = [for k in range(0, lookup(var.instances, "web_count", 0)) : cidrhost(local.main_subnet, 21 + k)]

  health_check_timeout = "5s"
  health_check_delay   = "30s"
  health_check_http {
    uri = "/healthz"
  }
}

resource "scaleway_lb_backend" "web_https" {
  count            = local.lb_enable ? 1 : 0
  lb_id            = scaleway_lb.lb[0].id
  name             = "web"
  forward_protocol = "tcp"
  forward_port     = "443"
  server_ips       = [for k in range(0, lookup(var.instances, "web_count", 0)) : cidrhost(local.main_subnet, 21 + k)]

  health_check_timeout = "5s"
  health_check_delay   = "30s"
  health_check_https {
    uri = "/healthz"
  }
}

resource "scaleway_lb_frontend" "http" {
  count        = local.lb_enable ? 1 : 0
  lb_id        = scaleway_lb.lb[0].id
  backend_id   = scaleway_lb_backend.web[0].id
  name         = "http"
  inbound_port = "80"

  acl {
    name = "Allow controlplane IPs"
    action {
      type = "allow"
    }
    match {
      ip_subnet = try(scaleway_instance_ip.controlplane[*].address, "0.0.0.0/0")
    }
  }
  acl {
    name = "Allow whitlist IPs"
    action {
      type = "allow"
    }
    match {
      ip_subnet = concat(var.whitelist_web, var.whitelist_admins)
    }
  }
  acl {
    name = "Deny all"
    action {
      type = "deny"
    }
    match {
      ip_subnet = ["0.0.0.0/0"]
    }
  }
}

resource "scaleway_lb_frontend" "https" {
  count        = local.lb_enable ? 1 : 0
  lb_id        = scaleway_lb.lb[0].id
  backend_id   = scaleway_lb_backend.web_https[0].id
  name         = "https"
  inbound_port = "443"

  acl {
    name = "Allow whitlist IPs"
    action {
      type = "allow"
    }
    match {
      ip_subnet = concat(var.whitelist_web, var.whitelist_admins)
    }
  }
  acl {
    name = "Deny all"
    action {
      type = "deny"
    }
    match {
      ip_subnet = ["0.0.0.0/0"]
    }
  }
}
