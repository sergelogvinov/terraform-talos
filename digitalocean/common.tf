
# resource "digitalocean_ssh_key" "default" {
#   name       = "Terraform"
#   public_key = file("~/.ssh/terraform.pub")
# }

resource "digitalocean_custom_image" "talos" {
  # for_each    = { for idx, name in var.regions : name => idx }
  for_each    = { "ams3" : 0 }
  name        = "talos"
  regions     = [each.key]
  description = "Talos version ${var.talos_version}"
  url         = "https://github.com/siderolabs/talos/releases/download/${var.talos_version}/digital-ocean-amd64.raw.gz"
  tags        = var.tags
}
