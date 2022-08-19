
resource "azurerm_availability_set" "controlplane" {
  for_each            = { for idx, name in local.regions : name => idx }
  location            = each.key
  name                = "controlplane-${each.key}"
  resource_group_name = local.resource_group

  platform_update_domain_count = 1
  platform_fault_domain_count  = 2

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
  instance_type             = lookup(try(var.controlplane[each.key], {}), "instance_type", "Standard_B2ms")
  instance_image            = data.azurerm_shared_image_version.talos.id
  instance_tags             = merge(var.tags, { type = "infra" })
  instance_secgroup         = local.network_secgroup[each.key].controlplane
  instance_params = merge(var.kubernetes, {
    lbv4   = local.network_controlplane[each.key].controlplane_lb[0]
    lbv6   = try(local.network_controlplane[each.key].controlplane_lb[1], "")
    region = each.key

    ccm = templatefile("${path.module}/deployments/azure.json.tpl", {
      subscriptionId = local.subscription_id
      tenantId       = data.azurerm_client_config.terraform.tenant_id
      clientId       = var.ccm_username
      clientSecret   = var.ccm_password
      region         = each.key
      resourceGroup  = local.resource_group
      vnetName       = local.network[each.key].name
    })
  })

  network_internal = local.network_controlplane[each.key]
}

locals {
  lbv4s    = [for ip in flatten([for c in local.network_controlplane : c.controlplane_lb]) : ip if length(split(".", ip)) > 1]
  lbv6s    = [for ip in flatten([for c in local.network_controlplane : c.controlplane_lb]) : ip if length(split(":", ip)) > 1]
  endpoint = try(flatten([for c in module.controlplane : c.controlplane_endpoints])[0], "")
}

resource "azurerm_private_dns_a_record" "controlplane" {
  for_each            = toset(values({ for zone, name in local.network : zone => name.dns if name.dns != "" }))
  name                = "controlplane"
  resource_group_name = local.resource_group
  zone_name           = each.key
  ttl                 = 300
  records             = local.lbv4s

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_private_dns_aaaa_record" "controlplane" {
  for_each            = toset(values({ for zone, name in local.network : zone => name.dns if name.dns != "" && length(local.lbv6s) > 0 }))
  name                = "controlplane"
  resource_group_name = local.resource_group
  zone_name           = each.key
  ttl                 = 300
  records             = local.lbv6s

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_private_dns_a_record" "controlplane_zonal" {
  for_each            = { for idx, name in local.regions : name => idx if lookup(try(var.controlplane[name], {}), "count", 0) > 1 && local.network[name].dns != "" }
  name                = "controlplane-${each.key}"
  resource_group_name = local.resource_group
  zone_name           = local.network[each.key].dns
  ttl                 = 300
  records             = flatten(module.controlplane[each.key].controlplane_endpoints)

  tags = merge(var.tags, { type = "infra" })
}
