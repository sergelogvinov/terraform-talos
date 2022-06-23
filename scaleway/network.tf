
locals {
  main_subnet = cidrsubnet(var.vpc_main_cidr, 8, 0)
}

resource "scaleway_vpc_public_gateway_ip" "main" {
  tags = concat(var.tags, ["infra"])
}

resource "scaleway_vpc_public_gateway" "main" {
  name  = "main"
  type  = "VPC-GW-S"
  ip_id = scaleway_vpc_public_gateway_ip.main.id

  tags = concat(var.tags, ["infra"])
}

resource "scaleway_vpc_public_gateway_dhcp" "main" {
  subnet             = local.main_subnet
  push_default_route = true
  pool_low           = cidrhost(local.main_subnet, 16)

  lifecycle {
    ignore_changes = [
      dns_servers_override
    ]
  }
}

resource "scaleway_vpc_private_network" "main" {
  name = "main"

  tags = concat(var.tags, ["infra"])
}

resource "scaleway_vpc_gateway_network" "main" {
  gateway_id         = scaleway_vpc_public_gateway.main.id
  private_network_id = scaleway_vpc_private_network.main.id
  dhcp_id            = scaleway_vpc_public_gateway_dhcp.main.id
  cleanup_dhcp       = true
}

# resource "scaleway_vpc_public_gateway_pat_rule" "main" {
#   count        = lookup(var.controlplane, "count", 0)
#   gateway_id   = scaleway_vpc_public_gateway.main.id
#   private_ip   = cidrhost(local.main_subnet, 11)
#   private_port = 50000
#   public_port  = 50000
#   protocol     = "tcp"
#   depends_on   = [scaleway_vpc_gateway_network.main, scaleway_vpc_private_network.main]
# }
