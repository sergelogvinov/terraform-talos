
resource "hcloud_firewall" "controlplane" {
  name   = "controlplane"
  labels = merge(var.tags, { type = "infra", label = "master" })

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
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
    port       = 50000
    source_ips = ["0.0.0.0/0", "::/0"]
    # source_ips = var.whitelist_admins
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 6443
    source_ips = ["0.0.0.0/0", "::/0"]
    # source_ips = var.whitelist_admins
  }
}

resource "hcloud_firewall" "ingress" {
  name   = "web"
  labels = merge(var.tags, { type = "infra", label = "ingress" })

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
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
    source_ips = var.whitelist_admins
  }
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = var.whitelist_admins
  }
}

resource "hcloud_firewall" "worker" {
  name   = "worker"
  labels = merge(var.tags, { type = "infra", label = "worker" })

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
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
}