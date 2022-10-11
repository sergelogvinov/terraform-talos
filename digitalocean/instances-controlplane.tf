
# resource "digitalocean_droplet" "controlplane" {
#   count              = lookup(var.controlplane, "count", 0)
#   location           = element(var.regions, count.index)
#   name               = "controlplane-${count.index + 1}"
#   ssh_keys           = [digitalocean_ssh_key.default.fingerprint]
#   image              = var.image
#   region             = element(var.regions, count.index)
#   size               = lookup(var.controlplane, "type", "cpx11")
#   resize_disk        = false
#   private_networking = false
#   backups            = false
#   ipv6               = true
#   user_data          = ""

#   lifecycle {
#     ignore_changes = [
#       resize_disk,
#       image,
#       user_data,
#       ssh_keys,
#     ]
#   }
# }
