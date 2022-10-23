
resource "exoscale_security_group" "gw" {
  name        = "${var.project}-gw"
  description = "gateway"
}

resource "exoscale_security_group_rule" "gw_ssh_v4" {
  for_each          = { for idx, ip in var.whitelist_admin : ip => idx }
  security_group_id = exoscale_security_group.gw.id
  description       = "ssh"
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = each.key
  start_port        = 22
  end_port          = 22
}

resource "exoscale_security_group" "common" {
  name        = "${var.project}-common"
  description = "common"
}

resource "exoscale_security_group_rule" "common_ssh_v4" {
  security_group_id = exoscale_security_group.common.id
  description       = "ssh (IPv4)"
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 22
  end_port          = 22
}

# resource "exoscale_security_group_rule" "common_localnet_tcp_v4" {
#   security_group_id = exoscale_security_group.common.id
#   description       = "local network"
#   type              = "INGRESS"
#   protocol          = "TCP"
#   cidr              = var.network_cidr
#   start_port        = 1
#   end_port          = 65535
# }

# resource "exoscale_security_group_rule" "common_localnet_udp_v4" {
#   security_group_id = exoscale_security_group.common.id
#   description       = "local network"
#   type              = "INGRESS"
#   protocol          = "UDP"
#   cidr              = var.network_cidr
#   start_port        = 1
#   end_port          = 65535
# }

resource "exoscale_security_group_rule" "common_talos_kubespan" {
  for_each          = { for idx, ip in ["0.0.0.0/0", "::/0"] : ip => idx }
  security_group_id = exoscale_security_group.common.id
  description       = "talos kubespan"
  type              = "INGRESS"
  protocol          = "UDP"
  cidr              = each.key
  start_port        = 51820
  end_port          = 51820
}

resource "exoscale_security_group" "controlplane" {
  name        = "${var.project}-controlplane"
  description = "controlplane"
}

resource "exoscale_security_group_rule" "controlplane_api" {
  for_each          = { for idx, ip in var.whitelist_admin : ip => idx }
  security_group_id = exoscale_security_group.controlplane.id
  description       = "controlplane api"
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = each.key
  start_port        = 6443
  end_port          = 6443
}

resource "exoscale_security_group_rule" "controlplane_api_health" {
  security_group_id = exoscale_security_group.controlplane.id
  description       = "controlplane api"
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 6443
  end_port          = 6443
}

resource "exoscale_security_group_rule" "controlplane_talos" {
  for_each          = { for idx, ip in var.whitelist_admin : ip => idx }
  security_group_id = exoscale_security_group.controlplane.id
  description       = "talos"
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = each.key
  start_port        = 50000
  end_port          = 50001
}

resource "exoscale_security_group_rule" "controlplane_icmp" {
  for_each          = { for idx, ip in var.whitelist_admin : ip => idx if length(split(".", ip)) > 1 }
  security_group_id = exoscale_security_group.controlplane.id
  description       = "ping"
  type              = "INGRESS"
  protocol          = "ICMP"
  cidr              = each.key
  icmp_type         = 8
  icmp_code         = 0
}

resource "exoscale_security_group" "web" {
  name        = "${var.project}-web"
  description = "web"
}

resource "exoscale_security_group_rule" "web_http" {
  for_each          = { for idx, ip in var.whitelist_web : ip => idx }
  security_group_id = exoscale_security_group.web.id
  description       = "http"
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = each.key
  start_port        = 80
  end_port          = 80
}

resource "exoscale_security_group_rule" "web_https" {
  for_each          = { for idx, ip in var.whitelist_web : ip => idx }
  security_group_id = exoscale_security_group.web.id
  description       = "https"
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = each.key
  start_port        = 443
  end_port          = 443
}
