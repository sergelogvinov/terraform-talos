
packer {
  required_plugins {
    upcloud = {
      version = ">= 1.0.0"
      source  = "github.com/UpCloudLtd/upcloud"
    }
  }
}

source "upcloud" "talos" {
  username = var.upcloud_username
  password = var.upcloud_password
  zone     = var.upcloud_zone

  storage_uuid    = "01000000-0000-4000-8000-000020050100"
  storage_size    = 10
  template_prefix = "talos-system-disk"
  # clone_zones     = var.upcloud_zones
}

# FIXME
build {
  name    = "release"
  sources = ["source.upcloud.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "sync && xz -d -c /tmp/talos.raw.xz | dd of=/dev/vda && systemctl --force --force poweroff",
    ]
  }
}

build {
  name    = "develop"
  sources = ["source.upcloud.talos"]

  provisioner "file" {
    source      = "../../../talos/_out/upcloud-amd64.raw.xz"
    destination = "/tmp/talos.raw.xz"
  }
  provisioner "shell" {
    inline = [
      "sync && xz -d -c /tmp/talos.raw.xz | dd of=/dev/vda && sync",
    ]
  }
}
