
locals {
  contolplane_prefix = "controlplane"
  contolplane_labels = ""

  controlplanes = { for k in flatten([
    for regions in var.regions : [
      for inx in range(lookup(try(var.controlplane[regions], {}), "count", 0)) : {
        name : "${local.contolplane_prefix}-${regions}-${1 + inx}"
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
    alias_ips  = each.key == keys(local.controlplanes)[0] ? [local.ipv4_vip] : []
  }

  shutdown_before_deletion = true
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
  count            = local.lb_enable ? length(local.controlplanes) : 0
  type             = "server"
  load_balancer_id = hcloud_load_balancer.api[0].id
  server_id        = hcloud_server.controlplane[count.index].id
}

#
# Secure push talos config to the controlplane
#

resource "local_sensitive_file" "controlplane" {
  for_each = local.controlplanes
  content = templatefile("${path.module}/templates/controlplane.yaml.tpl",
    merge(local.kubernetes, try(var.instances["all"], {}), {
      name        = each.value.name
      nodeSubnets = hcloud_network_subnet.core.ip_range
      ipv4_vip    = local.ipv4_vip
      ipv4_local  = each.value.ip
      lbv4_local  = local.lbv4_local
      lbv4        = local.lbv4
      lbv6        = local.lbv6

      hcloud_network = hcloud_network.main.id
      hcloud_token   = var.hcloud_token
      hcloud_image   = data.hcloud_image.talos["amd64"].id
      hcloud_sshkey  = hcloud_ssh_key.infra.id
      hcloud_init = base64encode(templatefile("${path.module}/templates/worker.yaml.tpl",
        merge(local.kubernetes, try(var.instances["all"], {}), {
          lbv4        = local.ipv4_vip
          nodeSubnets = var.vpc_main_cidr
          labels      = "${local.worker_labels},hcloud/node-group=worker-as"
        })
      ))
      robot_user     = var.robot_user
      robot_password = var.robot_password
    })
  )
  filename        = "_cfgs/${each.value.name}.yaml"
  file_permission = "0600"
}

locals {
  controlplane_config = { for k, v in local.controlplanes : v.name => "talosctl apply-config --insecure --nodes ${hcloud_server.controlplane[k].ipv4_address} --config-patch @_cfgs/${v.name}.yaml --file _cfgs/controlplane.yaml" }
}

output "controlplane_config" {
  value = local.controlplane_config
}
