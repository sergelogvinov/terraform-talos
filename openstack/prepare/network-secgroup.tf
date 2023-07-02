
resource "openstack_networking_secgroup_v2" "common" {
  for_each    = { for idx, name in var.regions : name => idx }
  region      = each.key
  name        = "common"
  description = "Security group for all nodes"
}

resource "openstack_networking_secgroup_rule_v2" "common_icmp_ipv4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.common[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
}

resource "openstack_networking_secgroup_rule_v2" "common_icmp_ipv6" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.common[each.key].id
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "ipv6-icmp"
}

resource "openstack_networking_secgroup_rule_v2" "common_talos_ipv4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.common[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 50000
  port_range_max    = 50001
  remote_ip_prefix  = var.network_cidr
}

resource "openstack_networking_secgroup_rule_v2" "common_talos_ipv6" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.common[each.key].id
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 50000
  port_range_max    = 50001
  remote_ip_prefix  = local.network_cidr_v6
}

resource "openstack_networking_secgroup_rule_v2" "common_kubelet_ipv4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.common[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_ip_prefix  = var.network_cidr
}

resource "openstack_networking_secgroup_rule_v2" "common_kubelet_ipv6" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.common[each.key].id
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_ip_prefix  = local.network_cidr_v6
}

resource "openstack_networking_secgroup_rule_v2" "common_cilium_health_ipv4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.common[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 4240
  port_range_max    = 4240
  remote_ip_prefix  = var.network_cidr
}

resource "openstack_networking_secgroup_rule_v2" "common_cilium_health_ipv6" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.common[each.key].id
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 4240
  port_range_max    = 4240
  remote_ip_prefix  = "::/0" # cilium uses sometimes public ipv6
}

resource "openstack_networking_secgroup_rule_v2" "common_cilium_vxvlan" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.common[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  remote_ip_prefix  = var.network_cidr
}

### Controlplane

resource "openstack_networking_secgroup_v2" "controlplane" {
  for_each    = { for idx, name in var.regions : name => idx }
  region      = each.key
  name        = "controlplane"
  description = "Security group for controlplane"
}

resource "openstack_networking_secgroup_rule_v2" "controlplane_talos_admins" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.controlplane[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 50000
  port_range_max    = 50000
  remote_ip_prefix  = var.whitelist_admins[0]
}

# resource "openstack_networking_secgroup_rule_v2" "controlplane_talos_admins_ipv6" {
#   for_each          = { for idx, name in var.regions : name => idx }
#   region            = each.key
#   security_group_id = openstack_networking_secgroup_v2.controlplane[each.key].id
#   direction         = "ingress"
#   ethertype         = "IPv6"
#   protocol          = "tcp"
#   port_range_min    = 50000
#   port_range_max    = 50000
# }

resource "openstack_networking_secgroup_rule_v2" "controlplane_etcd_ipv4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.controlplane[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2380
  remote_ip_prefix  = var.network_cidr
}

resource "openstack_networking_secgroup_rule_v2" "controlplane_kubernetes_ipv4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.controlplane[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = var.network_cidr
}

resource "openstack_networking_secgroup_rule_v2" "controlplane_kubernetes_ipv6" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.controlplane[each.key].id
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = local.network_cidr_v6
}

resource "openstack_networking_secgroup_rule_v2" "controlplane_kubernetes_admins" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.controlplane[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = var.whitelist_admins[0]
}

### Web

resource "openstack_networking_secgroup_v2" "web" {
  for_each    = { for idx, name in var.regions : name => idx }
  region      = each.key
  name        = "web"
  description = "Security group for web"
}

resource "openstack_networking_secgroup_rule_v2" "web_http_v4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.web[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
}

resource "openstack_networking_secgroup_rule_v2" "web_https_v4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.web[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
}

resource "openstack_networking_secgroup_rule_v2" "web_https_v6" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.web[each.key].id
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
}

###

resource "openstack_networking_secgroup_v2" "router" {
  for_each    = { for idx, name in var.regions : name => idx }
  region      = each.key
  name        = "router"
  description = "Security group for router/peering node"
}

resource "openstack_networking_secgroup_rule_v2" "router_icmp_ipv4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.router[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
}

resource "openstack_networking_secgroup_rule_v2" "router_ssh_v4" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.router[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
}

resource "openstack_networking_secgroup_rule_v2" "router_ssh_v6" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.router[each.key].id
  direction         = "ingress"
  ethertype         = "IPv6"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
}

resource "openstack_networking_secgroup_rule_v2" "router_wireguard" {
  for_each          = { for idx, name in var.regions : name => idx }
  region            = each.key
  security_group_id = openstack_networking_secgroup_v2.router[each.key].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 443
  port_range_max    = 443
}
