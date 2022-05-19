
resource "azurerm_availability_set" "controlplane" {
  for_each            = { for idx, name in local.regions : name => idx }
  location            = each.key
  name                = "controlplane-${each.key}"
  resource_group_name = local.resource_group

  platform_update_domain_count = 1
  platform_fault_domain_count  = 1

  tags = merge(var.tags, { type = "infra" })
}

module "controlplane" {
  source          = "./modules/controlplane"
  for_each        = { for idx, name in local.regions : name => idx }
  region          = each.key
  subscription_id = local.subscription_id

  instance_availability_set = azurerm_availability_set.controlplane[each.key].id
  instance_count            = lookup(try(var.controlplane[each.key], {}), "count", 0)
  instance_resource_group   = local.resource_group
  instance_type             = lookup(try(var.controlplane[each.key], {}), "instance_type", "Standard_B2s")
  instance_image            = data.azurerm_image.talos[each.key].id
  instance_tags             = merge(var.tags, { type = "infra" })
  instance_secgroup         = local.network_secgroup[each.key].controlplane
  instance_params = merge(var.kubernetes, {
    lbv4   = local.network_public[each.key].controlplane_lb[0]
    lbv6   = try(local.network_public[each.key].controlplane_lb[1], "")
    region = each.key
  })

  network_internal = local.network_public[each.key]
}

locals {
  lbv4s    = [for c in local.network_public : c.controlplane_lb]
  endpoint = try(flatten([for c in module.controlplane : c.controlplane_endpoints])[0], "")
}
