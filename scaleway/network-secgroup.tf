
resource "scaleway_instance_security_group" "controlplane" {
  name                    = "controlplane"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  dynamic "inbound_rule" {
    for_each = ["50000", "50001", "6443", "2379", "2380"]

    content {
      action   = "accept"
      protocol = "TCP"
      port     = inbound_rule.value
    }
  }

  dynamic "inbound_rule" {
    for_each = ["50000", "50001", "6443"]

    content {
      action   = "accept"
      protocol = "TCP"
      port     = inbound_rule.value
      ip_range = "::/0"
    }
  }

  dynamic "inbound_rule" {
    for_each = ["10250"]

    content {
      action   = "accept"
      protocol = "TCP"
      port     = inbound_rule.value
    }
  }

  inbound_rule {
    action   = "accept"
    protocol = "UDP"
  }

  inbound_rule {
    action   = "accept"
    protocol = "ICMP"
  }
}

# resource "scaleway_instance_security_group" "web" {
#   name                    = "web"
#   inbound_default_policy  = "drop"
#   outbound_default_policy = "accept"

#   dynamic "inbound_rule" {
#     for_each = ["80", "443"]

#     content {
#       action   = "accept"
#       protocol = "TCP"
#       port     = inbound_rule.value
#     }
#   }

#   dynamic "inbound_rule" {
#     for_each = ["4240"]

#     content {
#       action   = "accept"
#       protocol = "TCP"
#       port     = inbound_rule.value
#       ip_range = "::/0"
#     }
#   }

#   inbound_rule {
#     action   = "accept"
#     protocol = "ICMP"
#   }
# }

# resource "scaleway_instance_security_group" "worker" {
#   name                    = "worker"
#   inbound_default_policy  = "drop"
#   outbound_default_policy = "accept"

#   dynamic "inbound_rule" {
#     for_each = ["4240"]

#     content {
#       action   = "accept"
#       protocol = "TCP"
#       port     = inbound_rule.value
#       ip_range = "::/0"
#     }
#   }

#   inbound_rule {
#     action   = "accept"
#     protocol = "ICMP"
#   }
# }
