
resource "oci_core_default_security_list" "main" {
  compartment_id             = var.compartment_ocid
  manage_default_resource_id = oci_core_vcn.main.default_security_list_id
  display_name               = "DefaultSecurityList"

  egress_security_rules {
    protocol    = 1
    destination = oci_core_vcn.main.cidr_block
    stateless   = true
  }
  egress_security_rules {
    protocol    = 58
    destination = oci_core_vcn.main.ipv6cidr_blocks[0]
    stateless   = true
  }
  dynamic "egress_security_rules" {
    for_each = ["0.0.0.0/0", "::/0"]
    content {
      protocol    = "all"
      destination = egress_security_rules.value
      stateless   = false
    }
  }

  ingress_security_rules {
    protocol  = 1
    source    = oci_core_vcn.main.cidr_block
    stateless = true
  }
  ingress_security_rules {
    protocol  = 58
    source    = oci_core_vcn.main.ipv6cidr_blocks[0]
    stateless = true
  }
  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = false
    icmp_options {
      type = 3
      code = 4
    }
  }
}

resource "oci_core_network_security_group" "cilium" {
  display_name   = "${var.project}-cilium"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = merge(var.tags, { "Kubernetes.Type" = "infra" })

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
resource "oci_core_network_security_group_security_rule" "cilium_vxvlan_in" {
  for_each = toset([oci_core_vcn.main.cidr_block, oci_core_vcn.main.ipv6cidr_blocks[0]])

  network_security_group_id = oci_core_network_security_group.cilium.id
  protocol                  = "17"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  udp_options {
    # source_port_range {
    #   min = 8472
    #   max = 8472
    # }
    destination_port_range {
      min = 8472
      max = 8472
    }
  }
}
# resource "oci_core_network_security_group_security_rule" "cilium_vxvlan_out" {
#   for_each = toset([oci_core_vcn.main.cidr_block, oci_core_vcn.main.ipv6cidr_blocks[0]])

#   network_security_group_id = oci_core_network_security_group.cilium.id
#   protocol                  = "17"
#   direction                 = "EGRESS"
#   destination               = each.value
#   stateless                 = true

#   udp_options {
#     source_port_range {
#       min = 8472
#       max = 8472
#     }
#     destination_port_range {
#       min = 8472
#       max = 8472
#     }
#   }
# }
resource "oci_core_network_security_group_security_rule" "cilium_health" {
  for_each = toset([oci_core_vcn.main.cidr_block, oci_core_vcn.main.ipv6cidr_blocks[0]])

  network_security_group_id = oci_core_network_security_group.cilium.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 4240
      max = 4240
    }
  }
}

resource "oci_core_network_security_group" "talos" {
  display_name   = "${var.project}-talos"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = merge(var.tags, { "Kubernetes.Type" = "infra" })

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_network_security_group_security_rule" "talos" {
  for_each = toset([oci_core_vcn.main.cidr_block, oci_core_vcn.main.ipv6cidr_blocks[0]])

  network_security_group_id = oci_core_network_security_group.talos.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 50000
      max = 50001
    }
  }
}
resource "oci_core_network_security_group_security_rule" "talos_admin" {
  for_each = toset(var.whitelist_admins)

  network_security_group_id = oci_core_network_security_group.talos.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 50000
      max = 50001
    }
  }
}
resource "oci_core_network_security_group_security_rule" "ntp" {
  for_each = toset(["0.0.0.0/0", "::/0"])

  network_security_group_id = oci_core_network_security_group.talos.id
  protocol                  = "17"
  direction                 = "EGRESS"
  destination               = each.value
  stateless                 = false

  udp_options {
    destination_port_range {
      min = 123
      max = 123
    }
  }
}

resource "oci_core_network_security_group" "contolplane_lb" {
  display_name   = "${var.project}-contolplane-lb"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = merge(var.tags, { "Kubernetes.Type" = "infra" })

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_network_security_group_security_rule" "kubernetes" {
  for_each = toset([oci_core_vcn.main.cidr_block, oci_core_vcn.main.ipv6cidr_blocks[0]])

  network_security_group_id = oci_core_network_security_group.contolplane_lb.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "kubernetes_admin" {
  for_each = toset(var.whitelist_admins)

  network_security_group_id = oci_core_network_security_group.contolplane_lb.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "kubernetes_talos_admin" {
  for_each = toset(var.whitelist_admins)

  network_security_group_id = oci_core_network_security_group.contolplane_lb.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 50000
      max = 50000
    }
  }
}

resource "oci_core_network_security_group" "contolplane" {
  display_name   = "${var.project}-contolplane"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = merge(var.tags, { "Kubernetes.Type" = "infra" })

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_kubernetes" {
  for_each = toset([oci_core_vcn.main.cidr_block, oci_core_vcn.main.ipv6cidr_blocks[0]])

  network_security_group_id = oci_core_network_security_group.contolplane.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_kubernetes_admin" {
  for_each = toset(var.whitelist_admins)

  network_security_group_id = oci_core_network_security_group.contolplane.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_etcd" {
  for_each = toset([oci_core_vcn.main.cidr_block])

  network_security_group_id = oci_core_network_security_group.contolplane.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 2379
      max = 2380
    }
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_kubelet" {
  for_each = toset([oci_core_vcn.main.cidr_block, oci_core_vcn.main.ipv6cidr_blocks[0]])

  network_security_group_id = oci_core_network_security_group.contolplane.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}

resource "oci_core_network_security_group" "web" {
  display_name   = "${var.project}-web"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = merge(var.tags, { "Kubernetes.Type" = "worker" })

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
resource "oci_core_network_security_group_security_rule" "web_kubelet" {
  for_each = toset([oci_core_vcn.main.cidr_block, oci_core_vcn.main.ipv6cidr_blocks[0]])

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}
resource "oci_core_network_security_group_security_rule" "web_http_lb" {
  for_each = toset([oci_core_vcn.main.cidr_block])

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}
resource "oci_core_network_security_group_security_rule" "web_https_lb" {
  for_each = toset([oci_core_vcn.main.cidr_block])

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "web_http_admin" {
  for_each = toset(var.whitelist_admins)

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}
resource "oci_core_network_security_group_security_rule" "web_https_admin" {
  for_each = toset(var.whitelist_admins)

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "web_http" {
  for_each = toset(var.whitelist_web)

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}
resource "oci_core_network_security_group_security_rule" "web_https" {
  for_each = toset(var.whitelist_web)

  network_security_group_id = oci_core_network_security_group.web.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group" "worker" {
  display_name   = "${var.project}-worker"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  defined_tags   = merge(var.tags, { "Kubernetes.Type" = "worker" })

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
resource "oci_core_network_security_group_security_rule" "worker_kubelet" {
  for_each = toset([oci_core_vcn.main.cidr_block, oci_core_vcn.main.ipv6cidr_blocks[0]])

  network_security_group_id = oci_core_network_security_group.worker.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = each.value
  stateless                 = false

  tcp_options {
    destination_port_range {
      min = 10250
      max = 10250
    }
  }
}
