
packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.4"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}

source "digitalocean" "talos" {
  api_token    = var.do_api_token
  image        = "debian-11-x64"
  region       = var.do_region
  size         = "s-1vcpu-512mb-10gb"
  monitoring   = false
  # rescue       = true
  ipv6         = true

  ssh_username = "root"

  snapshot_name    = "talos system disk"
  snapshot_regions = [var.do_region]
}

# FIXME
build {
  name    = "release"
  sources = ["source.digitalocean.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.raw.gz https://github.com/talos-systems/talos/releases/download/${var.talos_version}/digital-ocean-amd64.raw.gz",
      "gzip -d -c /tmp/talos.raw.gz | dd of=/dev/vda && sync",
    ]
  }
}

build {
  name    = "develop"
  sources = ["source.digitalocean.talos"]

  provisioner "file" {
    source      = "digital-ocean-amd64.raw.gz"
    destination = "/tmp/talos.raw.gz"
  }
  provisioner "shell" {
    inline = [
      "sync",
      "gzip -d -c /tmp/talos.raw.gz | dd of=/dev/vda && sync ||:",
    ]
  }
}
