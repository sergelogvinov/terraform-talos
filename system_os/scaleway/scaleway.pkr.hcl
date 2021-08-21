
packer {
  required_plugins {
    scaleway = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/scaleway"
    }
  }
}

source "scaleway" "talos" {
  project_id = var.scaleway_project_id
  access_key = var.scaleway_access_key
  secret_key = var.scaleway_secret_key

  image           = "debian_buster"
  zone            = var.scaleway_zone
  commercial_type = "DEV1-S"
  boottype        = "rescue"
  remove_volume   = true
  ssh_username    = "root"

  image_name    = "talos-system-disk"
  snapshot_name = "talos system disk"
}

build {
  name    = "release"
  sources = ["source.scaleway.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.tar.gz ${local.image}",
      "tar xOzf /tmp/talos.tar.gz | dd of=/dev/vda",
    ]
  }
}

build {
  name    = "develop"
  sources = ["source.scaleway.talos"]

  provisioner "file" {
    source      = "../../../talos-pr/_out/scaleway-amd64.tar.gz"
    destination = "/tmp/talos.tar.gz"
  }
  provisioner "shell" {
    inline = [
      "tar xOzf /tmp/talos.tar.gz | dd of=/dev/vda && sync",
    ]
  }
}
