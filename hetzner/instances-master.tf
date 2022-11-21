
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
      ipv4_vip       = local.ipv4_vip
      ipv4_local     = cidrhost(hcloud_network_subnet.core.ip_range, 11 + count.index)
      lbv4_local     = local.lbv4_local
      lbv4           = local.lbv4
      lbv6           = local.lbv6
      hcloud_network = hcloud_network.main.id
      hcloud_token   = var.hcloud_token
      hcloud_image   = data.hcloud_image.talos.id
      robot_user     = var.robot_user
      robot_password = var.robot_password
    })
  )

  lifecycle {
    ignore_changes = [
      network,
      image,
      server_type,
      user_data,
      ssh_keys,
    ]
  }
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
#       type           = "controlplane"
#       ipv4_vip       = local.ipv4_vip
#       ipv4_local     = cidrhost(hcloud_network_subnet.core.ip_range, 11 + count.index)
#       lbv4_local     = local.lbv4_local
#       lbv4           = local.lbv4
#       lbv6           = local.lbv6
#       hcloud_network = hcloud_network.main.id
#       hcloud_token   = var.hcloud_token
#       labels         = "topology.kubernetes.io/region=${hcloud_server.controlplane[count.index].location},topology.kubernetes.io/zone=${hcloud_server.controlplane[count.index].datacenter}"
#     })
#   )
#   filename        = "_cfgs/controlplane-${count.index + 1}.yaml"
#   file_permission = "0600"

#   depends_on = [hcloud_server.controlplane]
# }

# resource "null_resource" "controlplane" {
#   count = lookup(var.controlplane, "count", 0)
#   provisioner "local-exec" {
#     command = "sleep 60 && talosctl apply-config --insecure --nodes ${hcloud_server.controlplane[count.index].ipv4_address} --file _cfgs/controlplane-${count.index + 1}.yaml"
#   }
#   depends_on = [hcloud_load_balancer_target.api, local_file.controlplane]
# }
