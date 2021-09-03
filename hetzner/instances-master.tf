
resource "hcloud_server" "controlplane" {
  count       = lookup(var.controlplane, "count", 0)
  location    = element(var.regions, count.index)
  name        = "master-${count.index + 1}"
  image       = data.hcloud_image.talos.id
  server_type = lookup(var.controlplane, "type", "cpx11")
  ssh_keys    = [hcloud_ssh_key.infra.id]
  keep_disk   = true
  labels      = merge(var.tags, { type = "infra", label = "master" })

  firewall_ids = [hcloud_firewall.controlplane.id]
  network {
    network_id = hcloud_network.main.id
    ip         = cidrhost(hcloud_network_subnet.core.ip_range, 11 + count.index)
  }

  user_data = templatefile("${path.module}/templates/controlplane.yaml",
    merge(var.kubernetes, {
      name           = "master-${count.index + 1}"
      type           = count.index == 0 ? "init" : "controlplane"
      ipv4_vip       = count.index == 0 ? local.ipv4_vip : cidrhost(hcloud_network_subnet.core.ip_range, 11)
      ipv4_local     = cidrhost(hcloud_network_subnet.core.ip_range, 11 + count.index)
      lbv4_local     = local.lbv4_local
      lbv4           = local.lbv4
      lbv6           = local.lbv6
      hcloud_network = hcloud_network.main.id
      hcloud_token   = var.hcloud_token
    })
  )

  lifecycle {
    ignore_changes = [
      image,
      server_type,
      user_data,
      ssh_keys,
    ]
  }
}

#
# Local floating ip assign to controlplane[0]
#

resource "hcloud_server_network" "controlplane" {
  count     = lookup(var.controlplane, "count", 0) > 0 ? 1 : 0
  server_id = hcloud_server.controlplane[0].id
  subnet_id = hcloud_network_subnet.core.id
  ip        = cidrhost(hcloud_network_subnet.core.ip_range, 11)
  alias_ips = [local.ipv4_vip]
}

resource "hcloud_load_balancer_target" "api" {
  count            = local.lb_enable ? lookup(var.controlplane, "count", 0) : 0
  type             = "server"
  load_balancer_id = hcloud_load_balancer.api[0].id
  server_id        = hcloud_server.controlplane[count.index].id
}

#
# Secure push talos config to the controlplane
#

# resource "local_file" "controlplane" {
#   count = lookup(var.controlplane, "count", 0)
#   content = templatefile("${path.module}/templates/controlplane.yaml",
#     merge(var.kubernetes, {
#       name           = "master-${count.index + 1}"
#       type           = count.index == 0 ? "init" : "controlplane"
#       ipv4_vip       = local.ipv4_vip
#       ipv4_local     = cidrhost(hcloud_network_subnet.core.ip_range, 11 + count.index)
#       lbv4_local     = local.lbv4_local
#       lbv4           = local.lbv4
#       lbv6           = local.lbv6
#       hcloud_network = hcloud_network.main.id
#       hcloud_token   = var.hcloud_token
#     })
#   )
#   filename        = "_cfgs/controlplane-${count.index + 1}.yaml"
#   file_permission = "0640"

#   depends_on = [hcloud_server.controlplane]
# }

# resource "null_resource" "controlplane" {
#   count = lookup(var.controlplane, "count", 0)
#   provisioner "local-exec" {
#     command = "sleep 60 && talosctl apply-config --insecure --nodes ${hcloud_server.controlplane[count.index].ipv4_address} --file _cfgs/controlplane-${count.index + 1}.yaml"
#   }
#   depends_on = [hcloud_load_balancer_target.api, local_file.controlplane]
# }
