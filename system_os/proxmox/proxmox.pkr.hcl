
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

  # iso_url          = "http://mirror.rackspace.com/archlinux/iso/2021.09.01/archlinux-2021.09.01-x86_64.iso"
  # iso_checksum     = "sha1:a0862c8189290e037ff156b93c60d6150b9363b3"
  # iso_storage_pool = "local"
  iso_file    = "local:iso/archlinux-2021.09.01-x86_64.iso"
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
  ssh_password = "packer"
  ssh_timeout  = "15m"
  qemu_agent   = true

  template_name        = "talos"
  template_description = "Talos system disk"

  boot_wait    = "15s"
  boot_command = [
    "<enter><wait1m>",
    "passwd<enter>packer<enter>packer<enter>"
  ]
}

build {
  name    = "release"
  sources = ["source.proxmox.talos"]

  provisioner "shell" {
    inline = [
      "curl -L ${local.image} -o /tmp/talos.raw.xz",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
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
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}
