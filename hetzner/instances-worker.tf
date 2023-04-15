
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
    merge(var.kubernetes, {
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

  lifecycle {
    ignore_changes = [
      image,
      server_type,
      user_data,
      ssh_keys,
    ]
  }
}

# module "worker" {
#   source = "./modules/worker"

#   for_each = var.instances
#   location = each.key
#   labels   = merge(var.tags, { label = "worker" })
#   network  = hcloud_network.main.id
#   subnet   = hcloud_network_subnet.core.ip_range

#   vm_name           = "worker-${each.key}-"
#   vm_items          = lookup(each.value, "worker_count", 0)
#   vm_type           = lookup(each.value, "worker_type", "cx11")
#   vm_image          = data.hcloud_image.talos.id
#   vm_ip_start       = (6 + try(index(var.regions, each.key), 0)) * 10
#   vm_security_group = [hcloud_firewall.worker.id]

#   vm_params = merge(var.kubernetes, {
#     lbv4   = local.ipv4_vip
#     labels = "project.io/node-pool=worker,hcloud/node-group=worker-${each.key}"
#   })
# }
