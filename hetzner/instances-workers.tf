
module "worker" {
  source = "./modules/worker"

  for_each = var.instances
  location = each.key
  labels   = merge(var.tags, { label = "worker" })
  network  = hcloud_network.main.id
  subnet   = hcloud_network_subnet.core.ip_range

  vm_name           = "worker-${each.key}-"
  vm_items          = lookup(each.value, "worker_count", 0)
  vm_type           = lookup(each.value, "worker_type", "cx11")
  vm_image          = data.hcloud_image.talos.id
  vm_ip_start       = (6 + try(index(var.regions, each.key), 0)) * 10
  vm_security_group = [hcloud_firewall.worker.id]

  vm_params = merge(var.kubernetes, {
    lbv4   = local.ipv4_vip
    labels = "project.io/node-pool=web,node.kubernetes.io/disktype=ssd,topology.kubernetes.io/region=${each.key},hcloud/node-group=worker-${each.key}"
  })
}
