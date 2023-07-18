
locals {
  worker_labels = "project.io/node-pool=worker"
}

resource "azurerm_linux_virtual_machine_scale_set" "worker" {
  for_each = { for idx, name in local.regions : name => idx }
  location = each.key

  instances                    = lookup(try(var.instances[each.key], {}), "worker_count", 0)
  name                         = "worker-${lower(each.key)}"
  computer_name_prefix         = "worker-${lower(each.key)}-"
  resource_group_name          = local.resource_group
  sku                          = lookup(try(var.instances[each.key], {}), "worker_type", "Standard_B2s")
  provision_vm_agent           = false
  overprovision                = false
  platform_fault_domain_count  = 5
  proximity_placement_group_id = length(var.zones) == 1 ? azurerm_proximity_placement_group.common[each.key].id : null

  zone_balance = length(var.zones) > 1
  zones        = var.zones

  # extension_operations_enabled = true
  # extension {
  #   name                       = "KubeletHealth"
  #   publisher                  = "Microsoft.ManagedServices"
  #   type                       = "ApplicationHealthLinux"
  #   type_handler_version       = "1.0"
  #   auto_upgrade_minor_version = false

  #   settings = jsonencode({
  #     protocol : "http"
  #     port : "10248"
  #     requestPath : "/healthz"
  #     intervalInSeconds : 60
  #     numberOfProbes : 3
  #   })
  # }

  network_interface {
    name                      = "worker-${lower(each.key)}"
    primary                   = true
    network_security_group_id = local.network_secgroup[each.key].common

    enable_accelerated_networking = lookup(try(var.instances[each.key], {}), "worker_os_ephemeral", false)
    ip_configuration {
      name      = "worker-${lower(each.key)}-v4"
      primary   = true
      version   = "IPv4"
      subnet_id = local.network_private[each.key].network_id
    }
    ip_configuration {
      name      = "worker-${lower(each.key)}-v6"
      version   = "IPv6"
      subnet_id = local.network_private[each.key].network_id

      dynamic "public_ip_address" {
        for_each = local.network_private[each.key].sku == "Standard" ? ["IPv6"] : []
        content {
          name    = "worker-${lower(each.key)}-v6"
          version = public_ip_address.value
        }
      }
    }
  }

  custom_data = base64encode(templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, var.acr, try(var.instances["all"], {}), {
      lbv4        = try(local.network_controlplane[each.key].controlplane_lb[0], "")
      labels      = local.worker_labels
      nodeSubnets = [local.network_private[each.key].cidr[0]]
    })
  ))

  admin_username = "talos"
  admin_ssh_key {
    username   = "talos"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadOnly"
    storage_account_type = lookup(try(var.instances[each.key], {}), "worker_os_ephemeral", false) ? "Standard_LRS" : "StandardSSD_LRS"
    disk_size_gb         = lookup(try(var.instances[each.key], {}), "worker_os_ephemeral", false) ? try(var.instances[each.key].worker_os_disk_size, 64) : 50

    dynamic "diff_disk_settings" {
      for_each = lookup(try(var.instances[each.key], {}), "worker_os_ephemeral", false) ? ["Local"] : []
      content {
        option    = diff_disk_settings.value
        placement = "ResourceDisk"
      }
    }
  }

  source_image_id = data.azurerm_shared_image_version.talos[length(regexall("^Standard_[DE][\\d+]p", lookup(try(var.instances[each.key], {}), "worker_type", ""))) > 0 ? "Arm64" : "x64"].id
  #   source_image_reference {
  #     publisher = "talos"
  #     offer     = "Talos"
  #     sku       = "1.0-dev"
  #     version   = "latest"
  #   }

  tags = merge(var.tags, {
    type                         = "worker",
    "cluster-autoscaler-enabled" = "true",
    "cluster-autoscaler-name"    = "${local.resource_group}-${lower(each.key)}",
    "min"                        = lookup(try(var.instances[each.key], {}), "worker_count", 0),
    "max"                        = 3,

    "k8s.io_cluster-autoscaler_node-template_label_project.io_node-pool" = "worker"
  })

  boot_diagnostics {}
  lifecycle {
    ignore_changes = [instances, admin_username, admin_ssh_key, source_image_id]
  }
}

resource "azurerm_linux_virtual_machine_scale_set" "worker_as" {
  for_each = { for idx, name in local.regions : name => idx }
  location = each.key

  instances                    = lookup(try(var.instances[each.key], {}), "worker_count", 0)
  name                         = "worker-${lower(each.key)}-as"
  computer_name_prefix         = "worker-${lower(each.key)}-as-"
  resource_group_name          = local.resource_group
  sku                          = lookup(try(var.instances[each.key], {}), "worker_type", "Standard_B2s")
  provision_vm_agent           = false
  overprovision                = false
  platform_fault_domain_count  = 1
  proximity_placement_group_id = length(var.zones) == 1 ? azurerm_proximity_placement_group.common[each.key].id : null

  zone_balance = length(var.zones) > 0
  zones        = var.zones

  eviction_policy = "Delete"
  priority        = "Spot"

  network_interface {
    name                      = "worker-${lower(each.key)}-as"
    primary                   = true
    network_security_group_id = local.network_secgroup[each.key].common

    enable_accelerated_networking = true
    ip_configuration {
      name      = "worker-${lower(each.key)}-as-v4"
      primary   = true
      version   = "IPv4"
      subnet_id = local.network_private[each.key].network_id
    }
    ip_configuration {
      name      = "worker-${lower(each.key)}-as-v6"
      version   = "IPv6"
      subnet_id = local.network_private[each.key].network_id

      dynamic "public_ip_address" {
        for_each = local.network_private[each.key].sku == "Standard" ? ["IPv6"] : []
        content {
          name    = "worker-${lower(each.key)}-as-v6"
          version = public_ip_address.value
        }
      }
    }
  }

  custom_data = base64encode(templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, var.acr, try(var.instances["all"], {}), {
      lbv4        = try(local.network_controlplane[each.key].controlplane_lb[0], "")
      labels      = local.worker_labels
      nodeSubnets = [local.network_private[each.key].cidr[0]]
    })
  ))

  admin_username = "talos"
  admin_ssh_key {
    username   = "talos"
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = try(var.instances[each.key].worker_os_disk_size, 64)

    diff_disk_settings {
      option    = "Local"
      placement = "ResourceDisk"
    }
  }

  source_image_id = data.azurerm_shared_image_version.talos[length(regexall("^Standard_[DE][\\d+]p", lookup(try(var.instances[each.key], {}), "worker_type", ""))) > 0 ? "Arm64" : "x64"].id
  #   source_image_reference {
  #     publisher = "talos"
  #     offer     = "Talos"
  #     sku       = "1.0-dev"
  #     version   = "latest"
  #   }

  tags = merge(var.tags, {
    type                         = "worker",
    "cluster-autoscaler-enabled" = "true",
    "cluster-autoscaler-name"    = "${local.resource_group}-${lower(each.key)}",
    "min"                        = 0,
    "max"                        = 3,

    "k8s.io_cluster-autoscaler_node-template_label_project.io_node-pool" = "worker"
  })

  boot_diagnostics {}
  lifecycle {
    ignore_changes = [instances, admin_username, admin_ssh_key, source_image_id]
  }
}
