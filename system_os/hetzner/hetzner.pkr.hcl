
packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.4"
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
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
      "mount /dev/sda3 /mnt && sed -i 's/set timeout=3/set timeout=10/g' /mnt/grub/grub.cfg && umount /mnt"
    ]
  }
}

build {
  name    = "develop"
  sources = ["source.hcloud.talos"]

  provisioner "file" {
    source      = "hcloud-amd64.raw.xz"
    destination = "/tmp/talos.raw.xz"
  }
  provisioner "shell" {
    inline = [
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
      "mount /dev/sda3 /mnt && sed -i 's/set timeout=3/set timeout=10/g' /mnt/grub/grub.cfg && umount /mnt"
    ]
  }
}
