
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox" "talos" {
  proxmox_url              = "https://${var.proxmox_host}:8006/api2/json"
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  node                     = var.proxmox_nodename
  insecure_skip_tls_verify = true

  # FIXME
  iso_file    = "local:iso/debian-11.0.0-amd64-netinst.iso"
  unmount_iso = true

  scsi_controller = "virtio-scsi-pci"
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  disks {
    type              = "scsi"
    storage_pool      = var.proxmox_storage
    storage_pool_type = var.proxmox_storage_type
    format            = "raw"
    disk_size         = "1G"
    cache_mode        = "writethrough"
  }

  memory       = 2048
  ssh_username = "root"

  template_name        = "talos"
  template_description = "Talos system disk"
}

build {
  name    = "release"
  sources = ["source.proxmox.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/vda && sync",
    ]
  }
}

build {
  name    = "develop"
  sources = ["source.proxmox.talos"]

  provisioner "file" {
    source      = "../../../talos-pr/_out/nocloud-amd64.raw.xz"
    destination = "/tmp/talos.raw.xz"
  }
  provisioner "shell" {
    inline = [
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/vda && sync",
    ]
  }
}
