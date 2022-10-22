
data "exoscale_compute_template" "debian" {
  for_each = { for idx, name in var.regions : name => idx }
  zone     = each.key
  name     = "Linux Debian 11 (Bullseye) 64-bit"
}
