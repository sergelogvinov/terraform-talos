
locals {
  worker_prefix = "worker"
  worker_labels = "project.io/node-pool=worker"

  worker = { for k in flatten([
    for regions in var.regions : [
      for inx in range(lookup(try(var.instances[regions], {}), "worker_count", 0)) : {
        name : "${local.worker_prefix}-${regions}-${1 + inx}"
        image : data.hcloud_image.talos[startswith(lookup(try(var.instances[regions], {}), "worker_type", "cpx11"), "ca") ? "arm64" : "amd64"].id
        region : regions
        type : lookup(try(var.instances[regions], {}), "worker_type", "cpx11")
        ip : cidrhost(hcloud_network_subnet.core.ip_range, 80 + 10 * index(var.regions, regions) + inx)
      }
    ]
  ]) : k.name => k }
}

resource "hcloud_server" "worker" {
  for_each    = local.worker
  location    = each.value.region
  name        = each.value.name
  image       = each.value.image
  server_type = each.value.type
  ssh_keys    = [hcloud_ssh_key.infra.id]
  keep_disk   = true
  labels      = merge(var.tags, { label = "worker" })

  user_data = templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(local.kubernetes, try(var.instances["all"], {}), {
      name        = each.value.name
      ipv4        = each.value.ip
      lbv4        = local.ipv4_vip
      nodeSubnets = hcloud_network_subnet.core.ip_range
      labels      = "${local.worker_labels},hcloud/node-group=worker-${each.value.region}"
    })
  )

  firewall_ids = [hcloud_firewall.worker.id]
  network {
    network_id = hcloud_network.main.id
    ip         = each.value.ip
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  shutdown_before_deletion = true
  lifecycle {
    ignore_changes = [
      image,
      server_type,
      user_data,
      ssh_keys,
      public_net,
    ]
  }
}
