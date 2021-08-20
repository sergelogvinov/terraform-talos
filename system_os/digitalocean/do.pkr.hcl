
packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}

source "digitalocean" "talos" {
  api_token    = var.do_api_token
  image        = "debian-10-x64"
  region       = var.do_region
  size         = "s-1vcpu-1gb"
  monitoring   = false

  ipv6               = true
  private_networking = false

  ssh_username = "root"

  snapshot_name    = "talos system disk"
  snapshot_regions = [var.do_region]
}

# FIXME
build {
  sources = ["source.digitalocean.talos"]
  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/digital-ocean.tar.gz https://github.com/talos-systems/talos/releases/download/${var.talos_version}/digital-ocean-amd64.tar.gz",
      "cd /tmp && tar xzf /tmp/digital-ocean.tar.gz && dd if=/tmp/disk.raw of=/dev/vda",
    ]
  }
}
