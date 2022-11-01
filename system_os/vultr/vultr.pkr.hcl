
packer {
  required_plugins {
    vultr = {
      version = ">= 2.4.0"
      source  = "github.com/vultr/vultr"
    }
  }
}

source "vultr" "talos" {
  api_key   = var.vultr_api_key
  region_id = var.vultr_region
  plan_id   = "vc2-1c-2gb"

  # Arch Linux
  iso_id        = "08597093-bb6f-48c3-b812-37feeabff4b0"
  state_timeout = "10m"
  ssh_username  = "root"
  ssh_password  = "packer"

  instance_label       = "talos"
  snapshot_description = "talos system disk"
}

# FIXME
build {
  name    = "release"
  sources = ["source.vultr.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/vda",
    ]
  }
}

build {
  name    = "develop"
  sources = ["source.vultr.talos"]

  provisioner "file" {
    source      = "vultr-amd64.raw.xz"
    destination = "/tmp/talos.raw.xz"
  }
  provisioner "shell" {
    inline = [
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/vda",
    ]
  }
}
