
locals {
  web_prefix = "web"
  web_labels = "project.io/node-pool=web"

  web = { for k in flatten([
    for regions in var.regions : [
      for inx in range(lookup(try(var.instances[regions], {}), "web_count", 0)) : {
        name : "${local.web_prefix}-${regions}-${1 + inx}"
        image : data.hcloud_image.talos[startswith(lookup(try(var.instances[regions], {}), "web_type", "cpx11"), "ca") ? "arm64" : "amd64"].id
        region : regions
        type : lookup(try(var.instances[regions], {}), "web_type", "cpx11")
        ip : cidrhost(hcloud_network_subnet.core.ip_range, 40 + 10 * index(var.regions, regions) + inx)
      }
    ]
  ]) : k.name => k }
}

resource "hcloud_server" "web" {
  for_each    = local.web
  location    = each.value.region
  name        = each.value.name
  image       = each.value.image
  server_type = each.value.type
  ssh_keys    = [hcloud_ssh_key.infra.id]
  keep_disk   = true
  labels      = merge(var.tags, { label = "web" })

  user_data = templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, {
      name        = each.value.name
      ipv4        = each.value.ip
      lbv4        = local.ipv4_vip
      nodeSubnets = hcloud_network_subnet.core.ip_range
      labels      = "${local.web_labels},hcloud/node-group=web-${each.value.region}"
    })
  )

  firewall_ids = [hcloud_firewall.web.id]
  network {
    network_id = hcloud_network.main.id
    ip         = each.value.ip
  }

  lifecycle {
    ignore_changes = [
      image,
      server_type,
      user_data,
      ssh_keys,
    ]
  }
}
