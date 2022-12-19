
resource "hcloud_firewall" "controlplane" {
  name   = "controlplane"
  labels = merge(var.tags, { type = "infra", label = "controlplane" })

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = concat(var.whitelist_admins, [var.vpc_main_cidr, "::/0"])
  }
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = [var.vpc_main_cidr]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = [var.vpc_main_cidr]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = var.whitelist_admins
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = var.whitelist_admins
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = var.whitelist_admins
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "50000"
    source_ips = concat(var.whitelist_admins, [var.vpc_main_cidr])
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "50001"
    source_ips = [var.vpc_main_cidr]
  }
  # rule {
  #   direction  = "in"
  #   protocol   = "tcp"
  #   port       = "2379"
  #   source_ips = ["0.0.0.0/0"]
  # }
  # rule {
  #   direction  = "in"
  #   protocol   = "tcp"
  #   port       = "2380"
  #   source_ips = ["0.0.0.0/0"]
  # }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = concat(var.whitelist_admins, [var.vpc_main_cidr, "${local.lbv4}/32"])
  }

  # cilium health
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "4240"
    source_ips = ["::/0"]
  }
}

resource "hcloud_firewall" "web" {
  name   = "web"
  labels = merge(var.tags, { type = "infra", label = "web" })

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = [var.vpc_main_cidr, "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = [var.vpc_main_cidr]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = [var.vpc_main_cidr]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = var.whitelist_web
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = var.whitelist_web
  }

  # cilium health
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "4240"
    source_ips = ["::/0"]
  }
}

resource "hcloud_firewall" "worker" {
  name   = "worker"
  labels = merge(var.tags, { type = "infra", label = "worker" })

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = [var.vpc_main_cidr, "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = [var.vpc_main_cidr]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = [var.vpc_main_cidr]
  }

  # cilium health
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "4240"
    source_ips = ["::/0"]
  }
}

resource "hcloud_firewall" "autoscale" {
  name   = "worker-auto-scale"
  labels = merge(var.tags, { type = "infra", label = "worker-auto-scale" })

  # apply_to {
  #   label_selector = "hcloud/node-group=worker-hel"
  # }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = [var.vpc_main_cidr, "::/0"]
  }
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "any"
    source_ips = [var.vpc_main_cidr]
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "any"
    source_ips = [var.vpc_main_cidr]
  }

  # cilium health
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "4240"
    source_ips = ["::/0"]
  }
}
