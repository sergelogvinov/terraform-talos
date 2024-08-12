
resource "scaleway_instance_security_group" "controlplane" {
  name                    = "controlplane"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    action   = "accept"
    protocol = "ANY"
    ip_range = local.main_subnet
  }
  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 4240
    ip_range = "::/0"
  }

  dynamic "inbound_rule" {
    for_each = var.whitelist_admins

    content {
      action   = "accept"
      protocol = "TCP"
      port     = "6443"
      ip_range = length(split("/", inbound_rule.value)) == 2 ? inbound_rule.value : "${inbound_rule.value}/32"
    }
  }
  dynamic "inbound_rule" {
    for_each = var.whitelist_admins

    content {
      action   = "accept"
      protocol = "TCP"
      port     = "50000"
      ip_range = length(split("/", inbound_rule.value)) == 2 ? inbound_rule.value : "${inbound_rule.value}/32"
    }
  }

  dynamic "inbound_rule" {
    for_each = ["2379", "2380"]

    content {
      action   = "accept"
      protocol = "TCP"
      port     = inbound_rule.value
    }
  }

  # KubeSpan
  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = 51820
  }
  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = 51820
    ip_range = "::/0"
  }

  # inbound_rule {
  #   action   = "accept"
  #   protocol = "TCP"
  #   port     = 22
  # }

  inbound_rule {
    action   = "accept"
    protocol = "ICMP"
    ip_range = "::/0"
  }
}

resource "scaleway_instance_security_group" "web" {
  name                    = "web"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  dynamic "inbound_rule" {
    for_each = ["80", "443"]

    content {
      action   = "accept"
      protocol = "TCP"
      port     = inbound_rule.value
    }
  }

  inbound_rule {
    action   = "accept"
    protocol = "ANY"
    ip_range = local.main_subnet
  }

  # KubeSpan
  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = 51820
  }
  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = 51820
    ip_range = "::/0"
  }

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 4240
    ip_range = "::/0"
  }
  inbound_rule {
    action   = "accept"
    protocol = "ICMP"
    ip_range = "::/0"
  }
}

resource "scaleway_instance_security_group" "worker" {
  name                    = "worker"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  inbound_rule {
    action   = "accept"
    protocol = "ANY"
    ip_range = local.main_subnet
  }

  # KubeSpan
  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = 51820
  }
  inbound_rule {
    action   = "accept"
    protocol = "UDP"
    port     = 51820
    ip_range = "::/0"
  }

  inbound_rule {
    action   = "accept"
    protocol = "TCP"
    port     = 4240
    ip_range = "::/0"
  }
  inbound_rule {
    action   = "accept"
    protocol = "ICMP"
    ip_range = "::/0"
  }
}
