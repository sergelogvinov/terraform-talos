
resource "azurerm_lb" "controlplane" {
  for_each            = { for idx, name in var.regions : name => idx }
  location            = each.key
  name                = "controlplane-${each.key}"
  resource_group_name = var.resource_group
  sku                 = try(var.capabilities[each.key].network_lb_type, "Basic")

  dynamic "frontend_ip_configuration" {
    for_each = [for ip in azurerm_subnet.controlplane[each.key].address_prefixes : ip if try(var.capabilities[each.key].network_lb_type, "Basic") != "Basic" || length(split(".", ip)) > 1]

    content {
      name                          = "controlplane-lb-v${length(split(".", frontend_ip_configuration.value)) > 1 ? "4" : "6"}"
      subnet_id                     = azurerm_subnet.controlplane[each.key].id
      private_ip_address            = cidrhost(frontend_ip_configuration.value, -6)
      private_ip_address_version    = length(split(".", frontend_ip_configuration.value)) > 1 ? "IPv4" : "IPv6"
      private_ip_address_allocation = "Static"
    }
  }

  tags = merge(var.tags, { type = "infra" })
}

resource "azurerm_lb_probe" "controlplane" {
  for_each            = { for idx, name in var.regions : name => idx }
  name                = "controlplane-tcp-probe"
  loadbalancer_id     = azurerm_lb.controlplane[each.key].id
  interval_in_seconds = 30
  protocol            = "Tcp"
  port                = 6443
}

resource "azurerm_lb_backend_address_pool" "controlplane_v4" {
  for_each        = { for idx, name in var.regions : name => idx }
  loadbalancer_id = azurerm_lb.controlplane[each.key].id
  name            = "controlplane-pool-v4"
}

resource "azurerm_lb_backend_address_pool" "controlplane_v6" {
  for_each        = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_lb_type, "Basic") != "Basic" }
  loadbalancer_id = azurerm_lb.controlplane[each.key].id
  name            = "controlplane-pool-v6"
}

resource "azurerm_lb_rule" "kubernetes_v4" {
  for_each                       = { for idx, name in var.regions : name => idx }
  name                           = "controlplane-v4"
  loadbalancer_id                = azurerm_lb.controlplane[each.key].id
  frontend_ip_configuration_name = "controlplane-lb-v4"
  probe_id                       = azurerm_lb_probe.controlplane[each.key].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.controlplane_v4[each.key].id]
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  idle_timeout_in_minutes        = 30
  enable_tcp_reset               = try(var.capabilities[each.key].network_lb_type, "Basic") != "Basic"
}

resource "azurerm_lb_rule" "kubernetes_v6" {
  for_each                       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_lb_type, "Basic") != "Basic" }
  name                           = "controlplane-v6"
  loadbalancer_id                = azurerm_lb.controlplane[each.key].id
  frontend_ip_configuration_name = "controlplane-lb-v6"
  probe_id                       = azurerm_lb_probe.controlplane[each.key].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.controlplane_v6[each.key].id]
  protocol                       = "Tcp"
  frontend_port                  = 6443
  backend_port                   = 6443
  idle_timeout_in_minutes        = 30
  enable_tcp_reset               = try(var.capabilities[each.key].network_lb_type, "Basic") != "Basic"
}

# resource "azurerm_lb_rule" "talos" {
#   for_each                       = { for idx, name in var.regions : name => idx }
#   name                           = "controlplane-talos-v4"
#   loadbalancer_id                = azurerm_lb.controlplane[each.key].id
#   frontend_ip_configuration_name = "controlplane-lb-v4"
#   probe_id                       = azurerm_lb_probe.controlplane[each.key].id
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.controlplane_v4[each.key].id]
#   protocol                       = "Tcp"
#   frontend_port                  = 50000
#   backend_port                   = 50000
#   idle_timeout_in_minutes        = 30
#   enable_tcp_reset               = try(var.capabilities[each.key].network_lb_type, "Basic") != "Basic"
# }

# resource "azurerm_lb_rule" "talos_v6" {
#   for_each                       = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_lb_type, "Basic") != "Basic" }
#   name                           = "controlplane-talos-v6"
#   loadbalancer_id                = azurerm_lb.controlplane[each.key].id
#   frontend_ip_configuration_name = "controlplane-lb-v6"
#   probe_id                       = azurerm_lb_probe.controlplane[each.key].id
#   backend_address_pool_ids       = [azurerm_lb_backend_address_pool.controlplane_v6[each.key].id]
#   protocol                       = "Tcp"
#   frontend_port                  = 50000
#   backend_port                   = 50000
#   idle_timeout_in_minutes        = 30
#   enable_tcp_reset               = try(var.capabilities[each.key].network_lb_type, "Basic") != "Basic"
# }
