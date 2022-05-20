
resource "azurerm_public_ip" "web_v4" {
  for_each            = { for idx, name in local.regions : name => idx }
  location            = each.key
  name                = "web-${lower(each.key)}-v4"
  resource_group_name = local.resource_group
  sku                 = local.network_public[each.key].sku
  allocation_method   = local.network_public[each.key].sku == "Standard" ? "Static" : "Dynamic"

  tags = merge(var.tags, { type = "web" })
}

resource "azurerm_lb" "web" {
  for_each            = { for idx, name in local.regions : name => idx }
  location            = each.key
  name                = "web-${lower(each.key)}"
  resource_group_name = local.resource_group
  sku                 = local.network_public[each.key].sku

  frontend_ip_configuration {
    name                 = "web-lb-v4"
    public_ip_address_id = azurerm_public_ip.web_v4[each.key].id
  }

  tags = merge(var.tags, { type = "web" })
}

resource "azurerm_lb_backend_address_pool" "web_v4" {
  for_each        = { for idx, name in local.regions : name => idx }
  loadbalancer_id = azurerm_lb.web[each.key].id
  name            = "web-pool-v4"
}

resource "azurerm_lb_probe" "web" {
  for_each            = { for idx, name in local.regions : name => idx }
  name                = "web-http-probe"
  loadbalancer_id     = azurerm_lb.web[each.key].id
  interval_in_seconds = 30
  protocol            = "Http"
  request_path        = "/healthz"
  port                = 80
}

resource "azurerm_lb_rule" "web_http_v4" {
  for_each                       = { for idx, name in local.regions : name => idx }
  name                           = "web_http-v4"
  loadbalancer_id                = azurerm_lb.web[each.key].id
  frontend_ip_configuration_name = "web-lb-v4"
  probe_id                       = azurerm_lb_probe.web[each.key].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_v4[each.key].id]
  enable_floating_ip             = false
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  idle_timeout_in_minutes        = 30
  enable_tcp_reset               = local.network_public[each.key].sku != "Basic"
}

resource "azurerm_lb_rule" "web_https_v4" {
  for_each                       = { for idx, name in local.regions : name => idx }
  name                           = "web-https-v4"
  loadbalancer_id                = azurerm_lb.web[each.key].id
  frontend_ip_configuration_name = "web-lb-v4"
  probe_id                       = azurerm_lb_probe.web[each.key].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web_v4[each.key].id]
  enable_floating_ip             = false
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  idle_timeout_in_minutes        = 30
  enable_tcp_reset               = local.network_public[each.key].sku != "Basic"
}

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

  extensions_time_budget = "PT30M"
  provision_vm_agent     = false

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

  source_image_id = data.azurerm_image.talos[each.key].id
  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 50
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
