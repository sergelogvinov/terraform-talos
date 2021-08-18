
resource "hcloud_load_balancer" "api" {
  name               = "api"
  location           = var.regions[0]
  load_balancer_type = "lb11"
  labels             = merge(var.tags, { type = "infra" })

  provisioner "local-exec" {
    command = "echo LB: ${self.ipv4}"
  }
}

resource "hcloud_load_balancer_network" "api" {
  load_balancer_id = hcloud_load_balancer.api.id
  subnet_id        = hcloud_network_subnet.core.id
  ip               = cidrhost(hcloud_network_subnet.core.ip_range, 5)
}

resource "hcloud_load_balancer_service" "api" {
  load_balancer_id = hcloud_load_balancer.api.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
  proxyprotocol    = false

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 15
    timeout  = 5
    retries  = 3
  }
}

# resource "hcloud_load_balancer_service" "talos" {
#   load_balancer_id = hcloud_load_balancer.api.id
#   protocol         = "tcp"
#   listen_port      = 50000
#   destination_port = 50000
#   proxyprotocol    = false

#   health_check {
#     protocol = "tcp"
#     port     = 50000
#     interval = 30
#     timeout  = 5
#     retries  = 3
#   }
# }

# resource "hcloud_load_balancer_service" "https" {
#   load_balancer_id = hcloud_load_balancer.api.id
#   protocol         = "tcp"
#   listen_port      = 443
#   destination_port = 443
#   proxyprotocol    = false

#   health_check {
#     protocol = "http"
#     port     = 80
#     interval = 30
#     timeout  = 5
#     retries  = 3
#     http {
#       path = "/healthz"
#     }
#   }
# }

# resource "hcloud_load_balancer_target" "https" {
#   type             = "label_selector"
#   load_balancer_id = hcloud_load_balancer.api.id
#   label_selector   = "label=web"
# }
