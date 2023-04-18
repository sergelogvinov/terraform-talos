
packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.5"
      source  = "github.com/hashicorp/hcloud"
    }
  }
}

source "hcloud" "talos" {
  token       = var.hcloud_token
  rescue      = "linux64"
  image       = "debian-11"
  location    = var.hcloud_location
  server_type = var.hcloud_type

  ssh_username                 = "root"
  ssh_timeout                  = "15m"
  ssh_disable_agent_forwarding = true

  snapshot_name = "talos system disk ${substr(var.hcloud_type, 0, 2) == "ca" ? "arm64" : "amd64"}"
  snapshot_labels = {
    type    = "infra",
    os      = "talos",
    arch    = substr(var.hcloud_type, 0, 2) == "ca" ? "arm64" : "amd64",
    version = "${var.talos_version}",
  }
}

build {
  name    = "release"
  sources = ["source.hcloud.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "export ARCH=${substr(var.hcloud_type, 0, 2) == "ca" ? "arm64" : "amd64"}",
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "sync && xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
      "mount /dev/sda3 /mnt && sed -i 's/set timeout=3/set timeout=10/g' /mnt/grub/grub.cfg && umount /mnt"
    ]
  }
}
