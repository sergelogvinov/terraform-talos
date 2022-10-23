
data "exoscale_compute_template" "debian" {
  for_each = { for idx, name in local.regions : name => idx if try(var.controlplane[name].count, 0) > 0 }
  zone     = each.key
  name     = "talos"
  filter   = "mine"
}

resource "exoscale_ssh_key" "terraform" {
  name       = "terraform"
  public_key = file("~/.ssh/terraform.pub")
}
