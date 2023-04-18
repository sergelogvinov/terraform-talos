
locals {
  contolplane_labels = ""

  controlplanes = { for k in flatten([
    for regions in var.regions : [
      for inx in range(lookup(try(var.controlplane[regions], {}), "count", 0)) : {
        name : "controlplane-${regions}-${1 + inx}"
        image : data.hcloud_image.talos[startswith(lookup(try(var.controlplane[regions], {}), "type", "cpx11"), "ca") ? "arm64" : "amd64"].id
        region : regions
        type : lookup(try(var.controlplane[regions], {}), "type", "cpx11")
        ip : cidrhost(cidrsubnet(hcloud_network_subnet.core.ip_range, 6, 2 + index(var.regions, regions)), inx)
      }
    ]
  ]) : k.name => k }
}

resource "hcloud_server" "controlplane" {
  for_each    = local.controlplanes
  location    = each.value.region
  name        = each.value.name
  image       = each.value.image
  server_type = each.value.type
  ssh_keys    = [hcloud_ssh_key.infra.id]
  keep_disk   = true
  labels      = merge(var.tags, { type = "infra", label = "controlplane" })

  firewall_ids = [hcloud_firewall.controlplane.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.main.id
    ip         = each.value.ip
  }

  #   user_data = templatefile("${path.module}/templates/controlplane.yaml",
  #     merge(var.kubernetes, {
  #       name           = each.value.name
  #       ipv4_vip       = local.ipv4_vip
  #       ipv4_local     = each.value.ip
  #       lbv4_local     = local.lbv4_local
  #       lbv4           = local.lbv4
  #       lbv6           = local.lbv6
  #       hcloud_network = hcloud_network.main.id
  #       hcloud_token   = var.hcloud_token
  #       hcloud_image   = data.hcloud_image.talos["amd64"].id
  #       robot_user     = var.robot_user
  #       robot_password = var.robot_password
  #     })
  #   )

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

resource "local_file" "controlplane" {
  for_each = local.controlplanes

  content = templatefile("${path.module}/templates/controlplane.yaml.tpl",
    {
      name           = each.value.name
      apiDomain      = var.kubernetes["apiDomain"]
      domain         = var.kubernetes["domain"]
      podSubnets     = var.kubernetes["podSubnets"]
      serviceSubnets = var.kubernetes["serviceSubnets"]
      ipv4_vip       = local.ipv4_vip
      ipv4_local     = each.value.ip
      lbv4_local     = local.lbv4_local
      lbv4           = local.lbv4
      lbv6           = local.lbv6
      nodeSubnets    = hcloud_network_subnet.core.ip_range
      hcloud_network = hcloud_network.main.id
      hcloud_token   = var.hcloud_token
      hcloud_image   = data.hcloud_image.talos["amd64"].id
      hcloud_sshkey  = hcloud_ssh_key.infra.id
      robot_user     = var.robot_user
      robot_password = var.robot_password
    }
  )
  filename        = "_cfgs/${each.value.name}.yaml"
  file_permission = "0600"
}

resource "null_resource" "controlplane" {
  for_each = local.controlplanes
  provisioner "local-exec" {
    command = "sleep 30 && talosctl apply-config --insecure --nodes ${hcloud_server.controlplane[each.key].ipv4_address} --timeout 5m0s --config-patch @_cfgs/${each.value.name}.yaml --file _cfgs/controlplane.yaml"
  }
  depends_on = [hcloud_load_balancer_target.api, local_file.controlplane]
}
