
resource "azurerm_public_ip" "controlplane" {
  count                   = var.instance_count
  name                    = "controlplane-${lower(var.region)}-${count.index}"
  resource_group_name     = var.instance_resource_group
  location                = var.region
  sku                     = "Basic"
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 15

  tags = var.instance_tags
}

resource "azurerm_network_interface" "controlplane" {
  count               = var.instance_count
  name                = "controlplane-${lower(var.region)}-${count.index}"
  resource_group_name = var.instance_resource_group
  location            = var.region

  dynamic "ip_configuration" {
    for_each = var.network_internal.cidr

    content {
      name                          = "controlplane-${count.index}-v${length(split(".", ip_configuration.value)) > 1 ? "4" : "6"}"
      primary                       = length(split(".", ip_configuration.value)) > 1
      subnet_id                     = var.network_internal.network_id
      private_ip_address            = cidrhost(ip_configuration.value, var.instance_ip_start + count.index)
      private_ip_address_version    = length(split(".", ip_configuration.value)) > 1 ? "IPv4" : "IPv6"
      private_ip_address_allocation = "Static"
      public_ip_address_id          = length(split(".", ip_configuration.value)) > 1 ? azurerm_public_ip.controlplane[count.index].id : ""
    }
  }

  tags = var.instance_tags
}

resource "azurerm_network_interface_security_group_association" "controlplane" {
  count                     = length(var.instance_secgroup) > 0 ? var.instance_count : 0
  network_interface_id      = azurerm_network_interface.controlplane[count.index].id
  network_security_group_id = var.instance_secgroup
}

resource "azurerm_network_interface_backend_address_pool_association" "controlplane" {
  count                   = length(var.network_internal.controlplane_pool) > 0 ? var.instance_count : 0
  network_interface_id    = azurerm_network_interface.controlplane[count.index].id
  ip_configuration_name   = "controlplane-${count.index}-v4"
  backend_address_pool_id = var.network_internal.controlplane_pool
}

locals {
  ipv4_local  = var.instance_count > 0 ? azurerm_network_interface.controlplane[0].ip_configuration[0].private_ip_address : ""
  ipv4_public = var.instance_count > 0 ? try([for ip in azurerm_public_ip.controlplane : ip.ip_address if ip.ip_address != ""], []) : []

  controlplane_labels = "topology.kubernetes.io/region=${var.region},topology.kubernetes.io/zone=azure"
}

resource "azurerm_linux_virtual_machine" "controlplane" {
  count                      = var.instance_count
  name                       = "controlplane-${lower(var.region)}-${count.index}"
  computer_name              = "controlplane-${lower(var.region)}-${count.index}"
  resource_group_name        = var.instance_resource_group
  location                   = var.region
  extensions_time_budget     = "PT1H30M"
  size                       = var.instance_type
  allow_extension_operations = false
  provision_vm_agent         = false
  availability_set_id        = var.instance_availability_set
  network_interface_ids      = [azurerm_network_interface.controlplane[count.index].id]

  os_disk {
    name                 = "controlplane-${lower(var.region)}-${count.index}-boot"
    caching              = "ReadOnly"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 32
  }

  admin_username = "talos"
  admin_ssh_key {
    username   = "talos"
    public_key = file("~/.ssh/terraform.pub")
  }

  source_image_id = length(var.instance_image) > 0 ? var.instance_image : null
  dynamic "source_image_reference" {
    for_each = length(var.instance_image) == 0 ? ["debian"] : []
    content {
      publisher = "Debian"
      offer     = "debian-11"
      sku       = "11-gen2"
      version   = "latest"
    }
  }

  tags = var.instance_tags

  boot_diagnostics {}
  lifecycle {
    ignore_changes = [admin_username, admin_ssh_key, os_disk, custom_data, source_image_id, tags]
  }
}
