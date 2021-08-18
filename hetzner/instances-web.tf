
module "web" {
  source = "./modules/worker"

  for_each = var.instances
  location = each.key
  labels   = merge(var.tags, { label = "web" })
  network  = hcloud_network.main.id
  subnet   = hcloud_network_subnet.core.ip_range

  vm_name           = "web-${each.key}-"
  vm_items          = lookup(each.value, "web_count", 0)
  vm_type           = lookup(each.value, "web_instance_type", "cx11")
  vm_image          = data.hcloud_image.talos.id
  vm_ip_start       = (3 + index(var.regions, each.key)) * 10
  vm_security_group = [hcloud_firewall.web.id]

  vm_params = merge(var.kubernetes, {
    # lbv4   = hcloud_load_balancer_network.api.ip
    lbv4   = cidrhost(hcloud_network_subnet.core.ip_range, 10)
    labels = "node.kubernetes.io/role=web"
  })
}
