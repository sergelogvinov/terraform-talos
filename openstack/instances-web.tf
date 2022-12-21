
resource "openstack_compute_servergroup_v2" "web" {
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key
  name     = "web"
  policies = ["soft-anti-affinity"]
}

module "web" {
  source   = "./modules/worker"
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key

  instance_servergroup = openstack_compute_servergroup_v2.web[each.key].id
  instance_count       = lookup(try(var.instances[each.key], {}), "web_count", 0)
  instance_name        = "web"
  instance_flavor      = lookup(try(var.instances[each.key], {}), "web_instance_type", 0)
  instance_image       = data.openstack_images_image_v2.talos[each.key].id
  instance_tags        = concat(var.tags, ["web"])
  instance_secgroups   = [local.network_secgroup[each.key].common, local.network_secgroup[each.key].web]
  instance_params = merge(var.kubernetes, {
    ipv4_local_network = local.network[each.key].cidr
    ipv4_local_gw      = local.network_public[each.key].gateway
    lbv4               = module.controlplane[each.key].controlplane_lb != "" ? module.controlplane[each.key].controlplane_lb : one(local.lbv4s)
    # routes             = "\n${join("\n", formatlist("- network: %s", flatten([for zone in local.regions : local.network_subnets[zone] if zone != each.key])))}"
  })

  network_internal = local.network_public[each.key]
  network_external = local.network_external[each.key]
}
