
resource "azurerm_public_ip" "router_v4" {
  for_each            = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  location            = each.key
  name                = "router-${lower(each.key)}-v4"
  resource_group_name = azurerm_resource_group.kubernetes.name
  ip_version          = "IPv4"
  sku                 = azurerm_lb.controlplane[each.key].sku
  allocation_method   = azurerm_lb.controlplane[each.key].sku == "Standard" ? "Static" : "Dynamic"

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_public_ip" "router_v6" {
  for_each            = { for idx, name in var.regions : name => idx if azurerm_lb.controlplane[name].sku == "Standard" && try(var.capabilities[name].network_gw_enable, false) }
  location            = each.key
  name                = "router-${lower(each.key)}-v6"
  resource_group_name = azurerm_resource_group.kubernetes.name
  ip_version          = "IPv6"
  sku                 = azurerm_lb.controlplane[each.key].sku
  allocation_method   = "Static"

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_network_interface" "router" {
  for_each             = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  location             = each.key
  name                 = "router-${lower(each.key)}"
  resource_group_name  = azurerm_resource_group.kubernetes.name
  enable_ip_forwarding = true

  dynamic "ip_configuration" {
    for_each = azurerm_subnet.public[each.key].address_prefixes

    content {
      name                          = "router-${lower(each.key)}-v${length(split(".", ip_configuration.value)) > 1 ? "4" : "6"}"
      primary                       = length(split(".", ip_configuration.value)) > 1
      subnet_id                     = azurerm_subnet.public[each.key].id
      private_ip_address            = cidrhost(ip_configuration.value, -2)
      private_ip_address_version    = length(split(".", ip_configuration.value)) > 1 ? "IPv4" : "IPv6"
      private_ip_address_allocation = "Static"
      public_ip_address_id          = length(split(".", ip_configuration.value)) > 1 ? azurerm_public_ip.router_v4[each.key].id : try(azurerm_public_ip.router_v6[each.key].id, "")
    }
  }

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_network_interface_security_group_association" "router" {
  for_each                  = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  network_interface_id      = azurerm_network_interface.router[each.key].id
  network_security_group_id = azurerm_network_security_group.gateway[each.key].id
}

# resource "azurerm_network_interface" "router_2" {
#   for_each            = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
#   location            = each.key
#   name                = "router-${lower(each.key)}-private"
#   resource_group_name = azurerm_resource_group.kubernetes.name

#   dynamic "ip_configuration" {
#     for_each = azurerm_subnet.private[each.key].address_prefixes

#     content {
#       name                          = "router-${lower(each.key)}-v${length(split(".", ip_configuration.value)) > 1 ? "4" : "6"}"
#       primary                       = length(split(".", ip_configuration.value)) > 1
#       subnet_id                     = azurerm_subnet.private[each.key].id
#       private_ip_address            = cidrhost(ip_configuration.value, -2)
#       private_ip_address_version    = length(split(".", ip_configuration.value)) > 1 ? "IPv4" : "IPv6"
#       private_ip_address_allocation = "Static"
#     }
#   }

#   tags = merge(var.tags, { type = "infra" })
# }

resource "azurerm_linux_virtual_machine" "router" {
  for_each                   = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  location                   = each.key
  name                       = "router-${lower(each.key)}"
  computer_name              = "router-${lower(each.key)}"
  resource_group_name        = azurerm_resource_group.kubernetes.name
  size                       = lookup(try(var.capabilities[each.key], {}), "network_gw_type", "Standard_B1s")
  allow_extension_operations = false
  provision_vm_agent         = false
  network_interface_ids      = [azurerm_network_interface.router[each.key].id]

  os_disk {
    name                 = "router-${lower(each.key)}"
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 32
  }

  admin_username = "debian"
  admin_ssh_key {
    username   = "debian"
    public_key = file("~/.ssh/terraform.pub")
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11-gen2"
    version   = "latest"
  }

  tags = merge(var.tags, { type = "infra" })

  boot_diagnostics {}
  lifecycle {
    ignore_changes = [admin_username, admin_ssh_key, os_disk, source_image_reference, tags]
  }
}
