
resource "hcloud_network" "main" {
  name     = "main"
  ip_range = var.vpc_main_cidr
  labels   = merge(var.tags, { type = "infra" })
}

resource "hcloud_network_subnet" "core" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = var.vpc_main_zone
  ip_range     = cidrsubnet(hcloud_network.main.ip_range, 8, 0)
}

resource "hcloud_network_subnet" "private" {
  network_id   = hcloud_network.main.id
  type         = "cloud"
  network_zone = var.vpc_main_zone
  ip_range     = cidrsubnet(hcloud_network.main.ip_range, 8, 1)
}

resource "hcloud_network_subnet" "robot" {
  count        = var.vpc_vswitch_id == 0 ? 0 : 1
  network_id   = hcloud_network.main.id
  type         = "vswitch"
  network_zone = var.vpc_main_zone
  vswitch_id   = var.vpc_vswitch_id
  ip_range     = cidrsubnet(hcloud_network.main.ip_range, 8, 2)
}
