
locals {
  lb_enable = lookup(var.controlplane, "type_lb", "") == "" ? false : true

  ipv4_vip = cidrhost(local.main_subnet, 5)
  lbv4     = local.lb_enable ? scaleway_lb_ip.lb_v4[0].ip_address : "127.0.0.1"
}

resource "scaleway_ipam_ip" "controlplane_vip" {
  address = cidrhost(local.main_subnet, 5)
  source {
    private_network_id = scaleway_vpc_private_network.main.id
  }
}

resource "scaleway_lb_ip" "lb_v4" {
  count = local.lb_enable ? 1 : 0
}
resource "scaleway_lb_ip" "lb_v6" {
  count   = local.lb_enable ? 1 : 0
  is_ipv6 = true
}

resource "scaleway_lb" "lb" {
  count = local.lb_enable ? 1 : 0
  name  = "controlplane"
  type  = lookup(var.controlplane, "type_lb", "LB-S")

  ip_ids = [scaleway_lb_ip.lb_v4[0].id, scaleway_lb_ip.lb_v6[0].id]
  private_network {
    private_network_id = scaleway_vpc_private_network.main.id
  }

  tags = concat(var.tags, ["infra"])
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
  acl {
    name = "Deny all"
    action {
      type = "deny"
    }
    match {
      ip_subnet = ["0.0.0.0/0", "::/0"]
    }
  }
}

###################

data "scaleway_ipam_ips" "web" {
  count    = lookup(try(var.instances[var.regions[0]], {}), "web_count", 0)
  type     = "ipv4"
  attached = true

  resource {
    name = scaleway_instance_server.web[count.index].name
    type = "instance_private_nic"
  }
}

resource "scaleway_lb_backend" "http" {
  count            = local.lb_enable ? 1 : 0
  lb_id            = scaleway_lb.lb[0].id
  name             = "http"
  forward_protocol = "http"
  forward_port     = "80"
  proxy_protocol   = "none"
  server_ips       = [for k in data.scaleway_ipam_ips.web : split("/", one(k.ips).address)[0]]

  health_check_timeout = "5s"
  health_check_delay   = "30s"
  health_check_http {
    uri = "/healthz"
  }
}

resource "scaleway_lb_frontend" "http" {
  count        = local.lb_enable ? 1 : 0
  lb_id        = scaleway_lb.lb[0].id
  backend_id   = scaleway_lb_backend.http[0].id
  name         = "http"
  inbound_port = "80"
}

###################

resource "scaleway_lb_backend" "https" {
  count            = local.lb_enable ? 1 : 0
  lb_id            = scaleway_lb.lb[0].id
  name             = "https"
  forward_protocol = "tcp"
  forward_port     = "443"
  proxy_protocol   = "none"
  server_ips       = [for k in data.scaleway_ipam_ips.web : split("/", one(k.ips).address)[0]]

  health_check_timeout = "5s"
  health_check_delay   = "15s"
  health_check_https {
    uri = "/healthz"
  }
}

resource "scaleway_lb_frontend" "https" {
  count        = local.lb_enable ? 1 : 0
  lb_id        = scaleway_lb.lb[0].id
  backend_id   = scaleway_lb_backend.https[0].id
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
