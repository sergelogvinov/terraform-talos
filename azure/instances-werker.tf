
# locals {
#   worker_labels = "topology.kubernetes.io/zone=azure,project.io/node-pool=worker"
# }

# resource "azurerm_linux_virtual_machine_scale_set" "worker" {
#   for_each = { for idx, name in local.regions : name => idx }
#   location = each.key

#   instances              = lookup(try(var.instances[each.key], {}), "worker_count", 0)
#   name                   = "worker-${lower(each.key)}"
#   computer_name_prefix   = "worker-${lower(each.key)}-"
#   resource_group_name    = local.resource_group
#   sku                    = lookup(try(var.instances[each.key], {}), "worker_instance_type", "Standard_B2s")
#   extensions_time_budget = "PT30M"
#   provision_vm_agent     = false
#   # availability_set_id        = var.instance_availability_set

#   network_interface {
#     name    = "worker-${lower(each.key)}"
#     primary = true
#     ip_configuration {
#       name      = "worker-${lower(each.key)}-v4"
#       primary   = true
#       version   = "IPv4"
#       subnet_id = local.network_private[each.key].network_id
#     }
#     ip_configuration {
#       name      = "worker-${lower(each.key)}-v6"
#       version   = "IPv6"
#       subnet_id = local.network_private[each.key].network_id
#     }
#   }

#   custom_data = base64encode(templatefile("${path.module}/templates/worker.yaml.tpl",
#     merge(var.kubernetes, {
#       lbv4        = local.network_public[each.key].controlplane_lb[0]
#       labels      = "topology.kubernetes.io/region=${each.key},${local.worker_labels}"
#       nodeSubnets = [local.network_private[each.key].cidr[0]]
#     })
#   ))

#   os_disk {
#     caching              = "ReadOnly"
#     storage_account_type = "StandardSSD_LRS"
#     disk_size_gb         = 50

# dynamic "diff_disk_settings" {
#   for_each = var.vm_os_ephemeral ? ["Local"] : []
#   content {
#     option = diff_disk_settings.value
#     placement = "ResourceDisk"
#   }
# }
#   }

#   disable_password_authentication = false
#   admin_password                  = "talos4PWD"
#   admin_username                  = "talos"
#   admin_ssh_key {
#     username   = "talos"
#     public_key = file("~/.ssh/terraform.pub")
#   }

#   source_image_id = data.azurerm_image.talos[each.key].id
#   # source_image_reference {
#   #   publisher = "Debian"
#   #   offer     = "debian-11"
#   #   sku       = "11-gen2"
#   #   version   = "latest"
#   # }

#   tags = merge(var.tags, { type = "worker" })

#   automatic_instance_repair {
#       ~ enabled      = true
#       ~ grace_period = "PT30M"
#   }

#   boot_diagnostics {}
#   lifecycle {
#     ignore_changes = [admin_username, admin_ssh_key, os_disk, source_image_id, tags]
#   }
# }
