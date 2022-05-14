
module "worker" {
  source   = "./modules/worker"
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key

  instance_count     = lookup(try(var.instances[each.key], {}), "worker_count", 0)
  instance_name      = "worker"
  instance_flavor    = lookup(try(var.instances[each.key], {}), "worker_instance_type", 0)
  instance_image     = data.openstack_images_image_v2.talos[each.key].id
  instance_secgroups = [local.network_secgroup[each.key].common.id]
  instance_params = merge(var.kubernetes, {
    ipv4_local_network = local.network[each.key].cidr
    ipv4_local_gw      = local.network_private[each.key].gateway
    lbv4               = module.controlplane[each.key].controlplane_lb != "" ? module.controlplane[each.key].controlplane_lb : one(local.lbv4s)
    routes             = "\n${join("\n", formatlist("- network: %s", flatten([for zone in local.regions : local.network_subnets[zone] if zone != each.key])))}"
  })

  network_internal = local.network_private[each.key]
  network_external = {
    id     = local.network_external[each.key].id
    subnet = local.network_external[each.key].subnets_v6[0]
    mtu    = local.network_external[each.key].mtu
  }
}
