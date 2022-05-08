
module "web" {
  source          = "./modules/worker"
  for_each        = { for idx, name in local.regions : name => idx }
  region          = each.key
  instance_count  = lookup(try(var.instances[each.key], {}), "web_count", 0)
  instance_name   = "web"
  instance_flavor = lookup(try(var.instances[each.key], {}), "web_instance_type", 0)
  instance_image  = data.openstack_images_image_v2.talos[each.key].id
  instance_params = merge(var.kubernetes, {
    ipv4_local_network = local.network[each.key].cidr
    ipv4_local_gw      = local.network_public[each.key].gateway
    lbv4               = module.controlplane[each.key].controlplane_lb
  })

  network_internal = local.network_public[each.key]
  network_external = local.network_external[each.key]
}
