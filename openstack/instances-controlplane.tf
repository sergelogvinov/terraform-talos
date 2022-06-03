
resource "openstack_compute_servergroup_v2" "controlplane" {
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key
  name     = "controlplane"
  policies = ["anti-affinity"]
}

module "controlplane" {
  source   = "./modules/controlplane"
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key

  instance_servergroup = openstack_compute_servergroup_v2.controlplane[each.key].id
  instance_count       = lookup(try(var.controlplane[each.key], {}), "count", 0)
  instance_flavor      = lookup(try(var.controlplane[each.key], {}), "instance_type", "d2-2")
  instance_image       = data.openstack_images_image_v2.talos[each.key].id
  instance_tags        = concat(var.tags, ["infra"])
  instance_secgroups   = [local.network_secgroup[each.key].common, local.network_secgroup[each.key].controlplane]
  instance_params = merge(var.kubernetes, {
    lbv4   = local.lbv4
    routes = "\n${join("\n", formatlist("- network: %s", flatten([for zone in local.regions : local.network_subnets[zone] if zone != each.key])))}"

    region              = each.key
    auth                = local.openstack_auth_url
    project_id          = local.project_id
    project_domain_id   = local.project_domain_id
    network_public_name = local.network_external[each.key].name

    occm = templatefile("${path.module}/deployments/openstack-cloud-controller-manager.conf.tpl", {
      username            = var.ccm_username
      password            = var.ccm_password
      region              = each.key
      auth                = local.openstack_auth_url
      project_id          = local.project_id
      project_domain_id   = local.project_domain_id
      network_public_name = local.network_external[each.key].name
    })
  })

  network_internal = local.network_public[each.key]
  network_external = local.network_external[each.key]
}

locals {
  lbv4s    = compact([for c in module.controlplane : c.controlplane_lb])
  endpoint = [for ip in try(flatten([for c in module.controlplane : c.controlplane_endpoints]), []) : ip if length(split(".", ip)) > 1]
}
