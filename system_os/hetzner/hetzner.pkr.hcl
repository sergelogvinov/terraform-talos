
packer {
  required_plugins {
    hcloud = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/hcloud"
    }
  }
}

variable "hcloud_token" {
  type      = string
  default   = "${env("HCLOUD_TOKEN")}"
  sensitive = true
}

variable "talos_version" {
  type    = string
  default = "v0.11.0"
}

source "hcloud" "talos" {
  token        = var.hcloud_token
  rescue       = "linux64"
  image        = "debian-10"
  location     = "hel1"
  server_type  = "cx11"
  ssh_username = "root"

  snapshot_name   = "talos system disk"
  snapshot_labels = {
      type    = "infra",
      os      = "talos",
      version = "${var.talos_version}",
  }
}

build {
  sources = ["source.hcloud.talos"]
  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/openstack.tar.gz https://github.com/talos-systems/talos/releases/download/${var.talos_version}/openstack-amd64.tar.gz",
      "cd /tmp && tar xzf /tmp/openstack.tar.gz && dd if=/tmp/disk.raw of=/dev/sda && sync",
    ]
  }
}
