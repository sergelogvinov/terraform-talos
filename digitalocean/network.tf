
resource "digitalocean_vpc" "main" {
  for_each = { for idx, name in var.regions : name => idx }
  name     = "main-${each.key}"
  region   = each.key
  ip_range = cidrsubnet(var.vpc_main_cidr, 8, each.value)
}
