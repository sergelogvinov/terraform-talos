
packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/hcloud"
    }
  }
}

source "hcloud" "talos" {
  token        = var.hcloud_token
  rescue       = "linux64"
  image        = "debian-11"
  location     = "hel1"
  server_type  = "cx11"
  ssh_username = "root"

  snapshot_name = "talos system disk"
  snapshot_labels = {
    type    = "infra",
    os      = "talos",
    version = "${var.talos_version}",
  }
}

build {
  name    = "release"
  sources = ["source.hcloud.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.tar.gz ${local.image}",
      "tar xOzf /tmp/talos.tar.gz | dd of=/dev/sda && sync",
    ]
  }
}

build {
  name    = "develop"
  sources = ["source.hcloud.talos"]

  provisioner "file" {
    source      = "../../../talos-pr/_out/hcloud-amd64.tar.gz"
    destination = "/tmp/talos.tar.gz"
  }
  provisioner "shell" {
    inline = [
      "tar xOzf /tmp/talos.tar.gz | dd of=/dev/sda && sync",
    ]
  }
}
