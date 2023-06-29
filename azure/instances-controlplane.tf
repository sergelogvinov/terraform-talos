
resource "azurerm_availability_set" "controlplane" {
  for_each            = { for idx, name in local.regions : name => idx }
  location            = each.key
  name                = "controlplane-${each.key}"
  resource_group_name = local.resource_group

  platform_update_domain_count = 1
  platform_fault_domain_count  = 2

  tags = merge(var.tags, { type = "infra" })
}

locals {
  controlplane_labels = "kubernetes.azure.com/managed=false"

  controlplanes = { for k in flatten([
    for region in local.regions : [
      for inx in range(lookup(try(var.controlplane[region], {}), "count", 0)) : {
        inx : inx
        name : "controlplane-${region}-${1 + inx}"
        region : region
        availability_set : azurerm_availability_set.controlplane[region].id

        image : data.azurerm_shared_image_version.talos[length(regexall("^Standard_[DE][\\d+]p", lookup(try(var.controlplane[region], {}), "type", ""))) > 0 ? "Arm64" : "x64"].id
        type : lookup(try(var.controlplane[region], {}), "type", "Standard_B2ms")

        ip : 11 + inx
        secgroup : local.network_secgroup[region].controlplane
        network : local.network_controlplane[region]
        vnetName : local.network[region].name
      }
    ]
  ]) : k.name => k }

  lbv4s = [for ip in flatten([for c in local.network_controlplane : c.controlplane_lb]) : ip if length(split(".", ip)) > 1]
  lbv6s = [for ip in flatten([for c in local.network_controlplane : c.controlplane_lb]) : ip if length(split(":", ip)) > 1]
  cpv4s = flatten([for cp in azurerm_network_interface.controlplane :
    [for ip in cp.ip_configuration : ip.private_ip_address if ip.private_ip_address_version == "IPv4"]
  ])
  cpv6s = flatten([for cp in azurerm_network_interface.controlplane :
    [for ip in cp.ip_configuration : ip.private_ip_address if ip.private_ip_address_version == "IPv6"]
  ])
}

resource "azurerm_public_ip" "controlplane_v4" {
  for_each                = local.controlplanes
  name                    = "${each.value.name}-v4"
  resource_group_name     = local.resource_group
  location                = each.value.region
  ip_version              = "IPv4"
  sku                     = each.value.network.sku
  allocation_method       = each.value.network.sku == "Standard" ? "Static" : "Dynamic"
  idle_timeout_in_minutes = 15

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_public_ip" "controlplane_v6" {
  for_each                = { for k, v in local.controlplanes : k => v if v.network.sku == "Standard" }
  name                    = "${each.value.name}-v6"
  resource_group_name     = local.resource_group
  location                = each.value.region
  ip_version              = "IPv6"
  sku                     = each.value.network.sku
  allocation_method       = "Static"
  idle_timeout_in_minutes = 15

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_network_interface" "controlplane" {
  for_each            = local.controlplanes
  name                = each.value.name
  resource_group_name = local.resource_group
  location            = each.value.region

  dynamic "ip_configuration" {
    for_each = each.value.network.cidr

    content {
      name                          = "${each.value.name}-v${length(split(".", ip_configuration.value)) > 1 ? "4" : "6"}"
      primary                       = length(split(".", ip_configuration.value)) > 1
      subnet_id                     = each.value.network.network_id
      private_ip_address            = cidrhost(ip_configuration.value, each.value.ip)
      private_ip_address_version    = length(split(".", ip_configuration.value)) > 1 ? "IPv4" : "IPv6"
      private_ip_address_allocation = "Static"
      public_ip_address_id          = length(split(".", ip_configuration.value)) > 1 ? azurerm_public_ip.controlplane_v4[each.key].id : try(azurerm_public_ip.controlplane_v6[each.key].id, null)
    }
  }

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_network_interface_security_group_association" "controlplane" {
  for_each                  = { for k, v in local.controlplanes : k => v if length(v.secgroup) > 0 }
  network_interface_id      = azurerm_network_interface.controlplane[each.key].id
  network_security_group_id = each.value.secgroup
}

# Different basic sku and standard sku load balancer or public Ip resources in availability set is not allowed
resource "azurerm_network_interface_backend_address_pool_association" "controlplane_v4" {
  for_each                = { for k, v in local.controlplanes : k => v if length(v.network.controlplane_pool_v4) > 0 }
  network_interface_id    = azurerm_network_interface.controlplane[each.key].id
  ip_configuration_name   = "${each.value.name}-v4"
  backend_address_pool_id = local.network_controlplane[each.value.region].controlplane_pool_v4
}

resource "azurerm_network_interface_backend_address_pool_association" "controlplane_v6" {
  for_each                = { for k, v in local.controlplanes : k => v if length(v.network.controlplane_pool_v6) > 0 }
  network_interface_id    = azurerm_network_interface.controlplane[each.key].id
  ip_configuration_name   = "${each.value.name}-v6"
  backend_address_pool_id = local.network_controlplane[each.value.region].controlplane_pool_v6
}

resource "local_file" "controlplane" {
  for_each = local.controlplanes

  content = templatefile("${path.module}/templates/controlplane.yaml.tpl",
    merge(var.kubernetes, var.acr, try(var.controlplane["all"], {}), {
      name   = each.value.name
      labels = local.controlplane_labels
      certSANs = flatten([
        var.kubernetes["apiDomain"],
        each.value.network.controlplane_lb,
        azurerm_public_ip.controlplane_v4[each.key].ip_address,
      ])
      ipAliases   = compact(each.value.network.controlplane_lb)
      nodeSubnets = [cidrsubnet(each.value.network.cidr[0], 1, 0)]

      ccm = templatefile("${path.module}/deployments/azure.json.tpl", {
        subscriptionId = local.subscription_id
        tenantId       = data.azurerm_client_config.terraform.tenant_id
        region         = local.regions[0] # each.value.region
        resourceGroup  = local.resource_group
        vnetName       = local.network[each.value.region].name
        tags           = join(",", [for k, v in var.tags : "${k}=${v}"])
      })
    })
  )
  filename        = "_cfgs/${each.value.name}.yaml"
  file_permission = "0600"
}

resource "azurerm_linux_virtual_machine" "controlplane" {
  for_each                   = local.controlplanes
  name                       = each.value.name
  computer_name              = each.value.name
  resource_group_name        = local.resource_group
  location                   = each.value.region
  size                       = each.value.type
  allow_extension_operations = false
  provision_vm_agent         = false
  availability_set_id        = each.value.availability_set
  network_interface_ids      = [azurerm_network_interface.controlplane[each.key].id]

  identity {
    type = "SystemAssigned"
  }

  # vtpm_enabled               = false
  # encryption_at_host_enabled = true
  os_disk {
    name                 = each.value.name
    caching              = "ReadOnly"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 48
  }

  admin_username = "talos"
  admin_ssh_key {
    username   = "talos"
    public_key = var.ssh_public_key
  }

  source_image_id = length(each.value.image) > 0 ? each.value.image : null
  dynamic "source_image_reference" {
    for_each = length(each.value.image) == 0 ? ["gallery"] : []
    content {
      publisher = "talos"
      offer     = "Talos"
      sku       = "MPL-2.0"
      version   = "latest"
    }
  }

  tags = merge(var.tags, { type = "infra" })

  boot_diagnostics {}
  lifecycle {
    ignore_changes = [admin_username, admin_ssh_key, os_disk, custom_data, source_image_id, tags]
  }
}

resource "azurerm_role_assignment" "controlplane" {
  for_each = { for k in flatten([
    for cp in azurerm_linux_virtual_machine.controlplane : [
      for role in var.controlplane_role_definition : {
        name : "role-${cp.name}-${role}"
        role : role
        principal : cp.identity[0].principal_id
      }
    ]
  ]) : k.name => k }
  scope                = "/subscriptions/${local.subscription_id}"
  role_definition_name = each.value.role
  principal_id         = each.value.principal
}

locals {
  controlplane_endpoints = try([for ip in azurerm_public_ip.controlplane_v4 : ip.ip_address if ip.ip_address != ""], [])
}

resource "azurerm_private_dns_a_record" "controlplane" {
  for_each            = toset(values({ for zone, name in local.network : zone => name.dns if name.dns != "" }))
  name                = split(".", var.kubernetes["apiDomain"])[0]
  resource_group_name = local.resource_group
  zone_name           = each.key
  ttl                 = 300
  records             = length(local.lbv4s) > 0 ? local.lbv4s : local.cpv4s

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_private_dns_aaaa_record" "controlplane" {
  for_each            = toset(values({ for zone, name in local.network : zone => name.dns if name.dns != "" && length(local.cpv6s) > 0 }))
  name                = split(".", var.kubernetes["apiDomain"])[0]
  resource_group_name = local.resource_group
  zone_name           = each.key
  ttl                 = 300
  records             = length(local.lbv6s) > 0 ? local.lbv6s : local.cpv6s

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_private_dns_a_record" "controlplane_zonal" {
  for_each            = { for idx, region in local.regions : region => idx if local.network[region].dns != "" }
  name                = "${split(".", var.kubernetes["apiDomain"])[0]}-${each.key}"
  resource_group_name = local.resource_group
  zone_name           = local.network[each.key].dns
  ttl                 = 300
  records = flatten([for cp in azurerm_network_interface.controlplane :
    [for ip in cp.ip_configuration : ip.private_ip_address if ip.private_ip_address_version == "IPv4"] if cp.location == each.key
  ])

  tags = merge(var.tags, { type = "infra" })
}
