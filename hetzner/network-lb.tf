
locals {
  lb_enable = try(var.controlplane["all"].type_lb, "") == "" ? false : true
}

locals {
  ipv4_vip   = cidrhost(hcloud_network_subnet.core.ip_range, 6)
  lbv4_local = cidrhost(hcloud_network_subnet.core.ip_range, 5)
  lbv4       = local.lb_enable ? hcloud_load_balancer.api[0].ipv4 : hcloud_floating_ip.api[0].ip_address
  lbv6       = local.lb_enable ? hcloud_load_balancer.api[0].ipv6 : local.ipv4_vip
}

resource "hcloud_floating_ip" "api" {
  count         = local.lb_enable ? 0 : 1
  name          = "api"
  home_location = var.regions[0]
  type          = "ipv4"
  labels        = merge(var.tags, { type = "infra" })
}

resource "hcloud_load_balancer" "api" {
  count              = local.lb_enable ? 1 : 0
  name               = "api"
  location           = var.regions[0]
  load_balancer_type = try(var.controlplane["all"].type_lb, "lb11")
  labels             = merge(var.tags, { type = "infra" })
}

resource "hcloud_load_balancer_network" "api" {
  count            = local.lb_enable ? 1 : 0
  load_balancer_id = hcloud_load_balancer.api[0].id
  subnet_id        = hcloud_network_subnet.core.id
  ip               = local.lbv4_local
}

resource "hcloud_load_balancer_service" "api" {
  count            = local.lb_enable ? 1 : 0
  load_balancer_id = hcloud_load_balancer.api[0].id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
  proxyprotocol    = false

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 15
    timeout  = 5
    retries  = 3
  }
}

# resource "hcloud_load_balancer_service" "talos" {
#   load_balancer_id = hcloud_load_balancer.api.id
#   protocol         = "tcp"
#   listen_port      = 50000
#   destination_port = 50000
#   proxyprotocol    = false

#   health_check {
#     protocol = "tcp"
#     port     = 50000
#     interval = 30
#     timeout  = 5
#     retries  = 3
#   }
# }

# resource "hcloud_load_balancer_service" "https" {
#   load_balancer_id = hcloud_load_balancer.api.id
#   protocol         = "tcp"
#   listen_port      = 443
#   destination_port = 443
#   proxyprotocol    = false

#   health_check {
#     protocol = "http"
#     port     = 80
#     interval = 30
#     timeout  = 5
#     retries  = 3
#     http {
#       path = "/healthz"
#     }
#   }
# }

# resource "hcloud_load_balancer_target" "https" {
#   type             = "label_selector"
#   load_balancer_id = hcloud_load_balancer.api.id
#   label_selector   = "label=web"
# }
