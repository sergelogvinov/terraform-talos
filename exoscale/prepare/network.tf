
resource "exoscale_private_network" "main" {
  for_each = { for idx, name in var.regions : name => idx }
  zone     = each.key
  name     = "${var.project}-${each.key}"

  netmask  = "255.255.255.0"
  start_ip = cidrhost(cidrsubnet(var.network_cidr, 8, var.network_shift + each.value * 2), 60)
  end_ip   = cidrhost(cidrsubnet(var.network_cidr, 8, var.network_shift + each.value * 2), -6)
}
