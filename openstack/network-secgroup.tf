

# resource "openstack_networking_secgroup_v2" "controlplane" {
#   count       = length(var.regions)
#   region      = element(var.regions, count.index)
#   name        = "api"
#   description = "Security group for allowing controlplane access"
# }

# resource "openstack_networking_secgroup_rule_v2" "controlplane_icmp_access_ipv4" {
#   count             = length(var.regions)
#   region            = element(var.regions, count.index)
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "icmp"
#   security_group_id = openstack_networking_secgroup_v2.controlplane[count.index].id
# }

# resource "openstack_networking_secgroup_rule_v2" "controlplane_icmp_access_ipv6" {
#   count             = length(var.regions)
#   region            = element(var.regions, count.index)
#   direction         = "ingress"
#   ethertype         = "IPv6"
#   protocol          = "icmp"
#   security_group_id = openstack_networking_secgroup_v2.controlplane[count.index].id
# }

# resource "openstack_networking_secgroup_rule_v2" "controlplane_ssh_access_ipv4" {
#   count             = length(var.regions)
#   region            = element(var.regions, count.index)
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 22
#   port_range_max    = 22
#   security_group_id = openstack_networking_secgroup_v2.controlplane[count.index].id
# }

# resource "openstack_networking_secgroup_rule_v2" "controlplane_talos_access_ipv4" {
#   count             = length(var.regions)
#   region            = element(var.regions, count.index)
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 50000
#   port_range_max    = 50000
#   security_group_id = openstack_networking_secgroup_v2.controlplane[count.index].id
# }

# resource "openstack_networking_secgroup_rule_v2" "controlplane_etcd_access_ipv4" {
#   count             = length(var.regions)
#   region            = element(var.regions, count.index)
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 2379
#   port_range_max    = 2380
#   security_group_id = openstack_networking_secgroup_v2.controlplane[count.index].id
# }

# resource "openstack_networking_secgroup_rule_v2" "controlplane_kubernetes_access_ipv4" {
#   count             = length(var.regions)
#   region            = element(var.regions, count.index)
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 6443
#   port_range_max    = 6443
#   security_group_id = openstack_networking_secgroup_v2.controlplane[count.index].id
# }

# resource "openstack_networking_secgroup_rule_v2" "controlplane_kubernetes_access_ipv6" {
#   count             = length(var.regions)
#   region            = element(var.regions, count.index)
#   direction         = "ingress"
#   ethertype         = "IPv6"
#   protocol          = "tcp"
#   port_range_min    = 6443
#   port_range_max    = 6443
#   security_group_id = openstack_networking_secgroup_v2.controlplane[count.index].id
# }

# resource "openstack_networking_secgroup_rule_v2" "controlplane_cilium_health_access_ipv4" {
#   count             = length(var.regions)
#   region            = element(var.regions, count.index)
#   direction         = "ingress"
#   ethertype         = "IPv4"
#   protocol          = "tcp"
#   port_range_min    = 4240
#   port_range_max    = 4240
#   security_group_id = openstack_networking_secgroup_v2.controlplane[count.index].id
# }

# resource "openstack_networking_secgroup_rule_v2" "controlplane_cilium_health_access_ipv6" {
#   count             = length(var.regions)
#   region            = element(var.regions, count.index)
#   direction         = "ingress"
#   ethertype         = "IPv6"
#   protocol          = "tcp"
#   port_range_min    = 4240
#   port_range_max    = 4240
#   security_group_id = openstack_networking_secgroup_v2.controlplane[count.index].id
# }
