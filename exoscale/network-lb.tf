
# resource "exoscale_nlb" "lb" {
#   for_each = { for idx, name in local.regions : name => idx if try(var.controlplane[name].count, 0) > 0 || try(var.instances[name].web_count, 0) > 0 }
#   zone     = each.key
#   name     = "lb-${each.key}"

#   labels = merge(var.tags, { type = "infra" })
# }

# resource "exoscale_nlb_service" "controlplane" {
#   for_each = { for idx, name in local.regions : name => idx if try(var.controlplane[name].count, 0) > 0 }
#   zone     = each.key
#   name     = "controlplane-${each.key}"

#   nlb_id      = exoscale_nlb.lb[each.key].id
#   protocol    = "tcp"
#   port        = 6443
#   target_port = 6443
#   strategy    = "round-robin"

#   healthcheck {
#     mode     = "tcp"
#     port     = 6443
#     interval = 15
#     timeout  = 3
#   }

#   instance_pool_id = exoscale_instance_pool.controlplane[each.key].id
# }

# resource "exoscale_nlb_service" "http" {
#   for_each = { for idx, name in local.regions : name => idx if try(var.instances[name].web_count, 0) > 0 }
#   zone     = each.key
#   name     = "web-http-${each.key}"

#   nlb_id      = exoscale_nlb.lb[each.key].id
#   protocol    = "tcp"
#   port        = 80
#   target_port = 80
#   strategy    = "round-robin"

#   healthcheck {
#     mode     = "http"
#     port     = 80
#     interval = 15
#     timeout  = 3
#     retries  = 2
#     uri      = "/"
#   }

#   instance_pool_id = exoscale_instance_pool.web[each.key].id
# }

# resource "exoscale_nlb_service" "https" {
#   for_each = { for idx, name in local.regions : name => idx if try(var.instances[name].web_count, 0) > 0 }
#   zone     = each.key
#   name     = "web-https-${each.key}"

#   nlb_id      = exoscale_nlb.lb[each.key].id
#   protocol    = "tcp"
#   port        = 443
#   target_port = 443
#   strategy    = "round-robin"

#   healthcheck {
#     mode     = "https"
#     port     = 443
#     interval = 15
#     timeout  = 3
#     retries  = 2
#     uri      = "/"
#   }

#   instance_pool_id = exoscale_instance_pool.web[each.key].id
# }
