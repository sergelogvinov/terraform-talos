
locals {
  lb_enable = lookup(var.controlplane, "lb", false) ? true : false

  lbv4 = local.lb_enable ? linode_nodebalancer.controlplane[0].ipv4 : try(linode_instance.controlplane[0].ip_address, "127.0.0.1")
}

resource "linode_nodebalancer" "controlplane" {
  count                = local.lb_enable ? 1 : 0
  label                = "controlplane"
  region               = var.region
  client_conn_throttle = 0
  tags                 = concat(var.tags, ["infra", "controlplane"])
}

resource "linode_nodebalancer_config" "controlplane" {
  count = local.lb_enable ? 1 : 0

  nodebalancer_id = linode_nodebalancer.controlplane[0].id
  port            = 6443
  protocol        = "tcp"

  check          = "connection"
  check_interval = 30
  check_attempts = 3
  check_timeout  = 5
}

resource "linode_nodebalancer_node" "controlplane" {
  count           = local.lb_enable ? lookup(var.controlplane, "count", 0) : 0
  nodebalancer_id = linode_nodebalancer.controlplane[0].id
  config_id       = linode_nodebalancer_config.controlplane[0].id
  address         = "${linode_instance.controlplane[count.index].private_ip_address}:6443"
  label           = "controlplane"
}

resource "linode_nodebalancer_config" "talos" {
  count = local.lb_enable ? 1 : 0

  nodebalancer_id = linode_nodebalancer.controlplane[0].id
  port            = 50000
  protocol        = "tcp"

  check          = "connection"
  check_interval = 30
  check_attempts = 3
  check_timeout  = 5
}

resource "linode_nodebalancer_node" "talos" {
  count           = local.lb_enable ? lookup(var.controlplane, "count", 0) : 0
  nodebalancer_id = linode_nodebalancer.controlplane[0].id
  config_id       = linode_nodebalancer_config.talos[0].id
  address         = "${linode_instance.controlplane[count.index].private_ip_address}:50000"
  label           = "talos"
}
