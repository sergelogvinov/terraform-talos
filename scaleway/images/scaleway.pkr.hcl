
packer {
  required_plugins {
    scaleway = {
      version = "= 1.2.0"
      source  = "github.com/hashicorp/scaleway"
    }
  }
}

source "scaleway" "talos" {
  project_id = var.scaleway_project_id
  access_key = var.scaleway_access_key
  secret_key = var.scaleway_secret_key

  image            = "debian_bookworm"
  image_size_in_gb = 10
  zone             = var.scaleway_zone
  commercial_type  = var.scaleway_type
  boottype         = "rescue"
  remove_volume    = true
  ssh_username     = "root"

  image_name    = "talos-system-disk-${substr(var.scaleway_type, 0, 6) == "COPARM" ? "arm64" : "amd64"}"
  snapshot_name = "talos system disk ${substr(var.scaleway_type, 0, 6) == "COPARM" ? "arm64" : "amd64"}"
  tags          = ["talos", "talos-system-disk", var.talos_version]
}

build {
  name    = "release"
  sources = ["source.scaleway.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "export ARCH=${substr(var.scaleway_type, 0, 6) == "COPARM" ? "arm64" : "amd64"}",
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
      "lsblk -f",
    ]
  }
}
