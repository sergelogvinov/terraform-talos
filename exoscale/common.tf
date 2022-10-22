
data "exoscale_compute_template" "debian" {
  for_each = { for idx, name in local.regions : name => idx }
  zone     = each.key
  name     = "Linux Debian 11 (Bullseye) 64-bit"
}

resource "exoscale_ssh_key" "terraform" {
  name       = "terraform"
  public_key = file("~/.ssh/terraform.pub")
}
