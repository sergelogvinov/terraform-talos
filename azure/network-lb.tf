
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
  disable_outbound_snat          = local.network_public[each.key].sku != "Basic"
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
  disable_outbound_snat          = local.network_public[each.key].sku != "Basic"
}

resource "azurerm_lb_outbound_rule" "web" {
  for_each                 = { for idx, name in local.regions : name => idx if local.network_public[name].sku != "Basic" }
  name                     = "snat"
  loadbalancer_id          = azurerm_lb.web[each.key].id
  backend_address_pool_id  = azurerm_lb_backend_address_pool.web_v4[each.key].id
  protocol                 = "All"
  allocated_outbound_ports = 1024

  frontend_ip_configuration {
    name = "web-lb-v4"
  }
}
