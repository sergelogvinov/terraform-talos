
resource "scaleway_instance_security_group" "controlplane" {
  name                    = "controlplane"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  dynamic "inbound_rule" {
    for_each = ["50000", "6443", "2379", "2380"]

    content {
      action   = "accept"
      protocol = "TCP"
      port     = inbound_rule.value
    }
  }

  dynamic "inbound_rule" {
    for_each = ["50000", "6443"]

    content {
      action   = "accept"
      protocol = "TCP"
      port     = inbound_rule.value
      ip_range = "::/0"
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
}
