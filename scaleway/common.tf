
data "scaleway_instance_image" "talos" {
  for_each     = toset(var.arch)
  name         = "talos-system-disk-${lower(each.key)}"
  architecture = each.key == "arm64" ? "arm64" : "x86_64"
}

resource "scaleway_account_ssh_key" "terraform" {
  name       = "terraform"
  public_key = file("~/.ssh/terraform.pub")
}
