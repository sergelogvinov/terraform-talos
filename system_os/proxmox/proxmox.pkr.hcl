
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

  iso_file = "local:iso/archlinux-2021.10.01-x86_64.iso"
  # iso_url          = "https://mirror.rackspace.com/archlinux/iso/2021.10.01/archlinux-2021.10.01-x86_64.iso"
  # iso_checksum     = "sha1:77a20dcd9d838398cebb2c7c15f46946bdc3855e"
  # iso_storage_pool = "local"
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

  boot_wait = "15s"
  boot_command = [
    "<enter><wait1m>",
    "passwd<enter><wait>packer<enter><wait>packer<enter>"
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
    source      = "../../../talos/_out/nocloud-amd64.raw.xz"
    destination = "/tmp/talos.raw.xz"
  }
  provisioner "shell" {
    inline = [
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}
