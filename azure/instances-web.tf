
locals {
  web_labels = "topology.kubernetes.io/zone=azure,project.io/node-pool=web"
}

resource "azurerm_linux_virtual_machine_scale_set" "web" {
  for_each = { for idx, name in local.regions : name => idx }
  location = each.key

  instances            = lookup(try(var.instances[each.key], {}), "web_count", 0)
  name                 = "web-${lower(each.key)}"
  computer_name_prefix = "web-${lower(each.key)}-"
  resource_group_name  = local.resource_group
  sku                  = lookup(try(var.instances[each.key], {}), "web_instance_type", "Standard_B2s")
  provision_vm_agent   = false
  overprovision        = false

  # availability_set_id        = var.instance_availability_set

  network_interface {
    name                      = "web-${lower(each.key)}"
    primary                   = true
    network_security_group_id = local.network_secgroup[each.key].web
    ip_configuration {
      name                                   = "web-${lower(each.key)}-v4"
      primary                                = true
      version                                = "IPv4"
      subnet_id                              = local.network_public[each.key].network_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.web_v4[each.key].id]
    }
    ip_configuration {
      name      = "web-${lower(each.key)}-v6"
      version   = "IPv6"
      subnet_id = local.network_public[each.key].network_id
    }
  }

  custom_data = base64encode(templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, {
      lbv4        = local.network_public[each.key].controlplane_lb[0]
      labels      = "topology.kubernetes.io/region=${each.key},${local.web_labels}"
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

  # source_image_id = data.azurerm_image.talos[each.key].id
  source_image_reference {
    publisher = "talos"
    offer     = "Talos"
    sku       = "1.0-dev"
    version   = "latest"
  }

  tags = merge(var.tags, { type = "web" })

  boot_diagnostics {}
  lifecycle {
    ignore_changes = [admin_username, admin_ssh_key, os_disk, source_image_id, tags]
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
