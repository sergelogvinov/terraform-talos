
locals {
  web_labels = "project.io/node-pool=web"
}

resource "azurerm_linux_virtual_machine_scale_set" "web" {
  for_each = { for idx, name in local.regions : name => idx }
  location = each.key

  instances                    = lookup(try(var.instances[each.key], {}), "web_count", 0)
  name                         = "web-${lower(each.key)}"
  computer_name_prefix         = "web-${lower(each.key)}-"
  resource_group_name          = local.resource_group
  sku                          = lookup(try(var.instances[each.key], {}), "web_type", "Standard_B2s")
  provision_vm_agent           = false
  overprovision                = false
  platform_fault_domain_count  = 2
  proximity_placement_group_id = azurerm_proximity_placement_group.common[each.key].id

  #   health_probe_id = local.network_public[each.key].sku != "Basic" ? azurerm_lb_probe.web[each.key].id : null
  #   automatic_instance_repair {
  #     enabled      = local.network_public[each.key].sku != "Basic"
  #     grace_period = "PT60M"
  #   }

  network_interface {
    name                      = "web-${lower(each.key)}"
    primary                   = true
    network_security_group_id = local.network_secgroup[each.key].web
    ip_configuration {
      name                                   = "web-${lower(each.key)}-v4"
      primary                                = true
      version                                = "IPv4"
      subnet_id                              = local.network_public[each.key].network_id
      load_balancer_backend_address_pool_ids = lookup(try(var.instances[each.key], {}), "web_count", 0) > 0 ? [azurerm_lb_backend_address_pool.web_v4[each.key].id] : []
    }
    ip_configuration {
      name      = "web-${lower(each.key)}-v6"
      version   = "IPv6"
      subnet_id = local.network_public[each.key].network_id

      dynamic "public_ip_address" {
        for_each = local.network_public[each.key].sku == "Standard" ? ["IPv6"] : []
        content {
          name    = "web-${lower(each.key)}-v6"
          version = public_ip_address.value
        }
      }
    }
  }

  custom_data = base64encode(templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, {
      lbv4        = local.network_controlplane[each.key].controlplane_lb[0]
      labels      = local.web_labels
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

  source_image_id = data.azurerm_shared_image_version.talos[startswith(lookup(try(var.instances[each.key], {}), "worker_type", ""), "Standard_D2p") ? "Arm64" : "x64"].id
  #   source_image_reference {
  #     publisher = "talos"
  #     offer     = "Talos"
  #     sku       = "1.0-dev"
  #     version   = "latest"
  #   }

  tags = merge(var.tags, {
    type                         = "web",
    "cluster-autoscaler-enabled" = "true",
    "cluster-autoscaler-name"    = "${local.resource_group}-${lower(each.key)}",
    "min"                        = 0,
    "max"                        = 3,

    "k8s.io_cluster-autoscaler_node-template_label_project.io_node-pool" = "web"
  })

  boot_diagnostics {}
  lifecycle {
    ignore_changes = [instances, admin_username, admin_ssh_key, os_disk, source_image_id]
  }
}

# resource "local_file" "web" {
#   for_each = { for idx, name in local.regions : name => idx }

#   content = templatefile("${path.module}/templates/worker.yaml.tpl",
#     merge(var.kubernetes, {
#       lbv4        = local.network_public[each.key].controlplane_lb[0]
#       labels      = "topology.kubernetes.io/region=${each.key},${local.web_labels}"
#       nodeSubnets = [local.network_public[each.key].cidr[0]]
#     })
#   )

#   filename        = "_cfgs/web-${lower(each.key)}.yaml"
#   file_permission = "0600"
# }
