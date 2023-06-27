
locals {
  db_labels = "project.io/node-pool=db"
}

resource "azurerm_linux_virtual_machine_scale_set" "db" {
  for_each = { for idx, name in local.regions : name => idx }
  location = each.key

  instances                    = lookup(try(var.instances[each.key], {}), "db_count", 0)
  name                         = "db-${lower(each.key)}"
  computer_name_prefix         = "db-${lower(each.key)}-"
  resource_group_name          = local.resource_group
  sku                          = lookup(try(var.instances[each.key], {}), "db_type", "Standard_B2s")
  provision_vm_agent           = false
  overprovision                = false
  platform_fault_domain_count  = 5
  proximity_placement_group_id = azurerm_proximity_placement_group.common[each.key].id

  # zone_balance = true
  # zones        = ["0", "1", "2"]

  network_interface {
    name                      = "db-${lower(each.key)}"
    primary                   = true
    network_security_group_id = local.network_secgroup[each.key].common

    ip_configuration {
      name      = "db-${lower(each.key)}-v4"
      primary   = true
      version   = "IPv4"
      subnet_id = local.network_private[each.key].network_id
    }
    ip_configuration {
      name      = "db-${lower(each.key)}-v6"
      version   = "IPv6"
      subnet_id = local.network_private[each.key].network_id

      dynamic "public_ip_address" {
        for_each = local.network_public[each.key].sku == "Standard" ? ["IPv6"] : []
        content {
          name    = "db-${lower(each.key)}-v6"
          version = public_ip_address.value
        }
      }
    }
  }

  custom_data = base64encode(templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, {
      lbv4        = try(local.network_controlplane[each.key].controlplane_lb[0], "")
      labels      = local.db_labels
      nodeSubnets = [local.network_public[each.key].cidr[0]]
    })
  ))

  admin_username = "talos"
  admin_ssh_key {
    username   = "talos"
    public_key = file("~/.ssh/terraform.pub")
  }

  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 50
  }

  source_image_id = data.azurerm_shared_image_version.talos[length(regexall("^Standard_[DE][\\d+]p", lookup(try(var.instances[each.key], {}), "db_type", ""))) > 0 ? "Arm64" : "x64"].id
  #   source_image_reference {
  #     publisher = "talos"
  #     offer     = "Talos"
  #     sku       = "1.0-dev"
  #     version   = "latest"
  #   }

  tags = merge(var.tags, {
    type                         = "db",
    "cluster-autoscaler-enabled" = "true",
    "cluster-autoscaler-name"    = "${local.resource_group}-${lower(each.key)}",
    "min"                        = 0,
    "max"                        = 3,

    "k8s.io_cluster-autoscaler_node-template_label_project.io_node-pool" = "db"
  })

  boot_diagnostics {}
  lifecycle {
    ignore_changes = [instances, admin_username, admin_ssh_key, os_disk, source_image_id]
  }
}
