
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
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

  iso_file = "local:iso/archlinux-2023.03.01-x86_64.iso"
  # iso_url          = "https://mirror.rackspace.com/archlinux/iso/2023.03.01/archlinux-2023.03.01-x86_64.iso"
  # iso_checksum     = "sha1:3ae7c83eca8bd698b4e54c49d43e8de5dc8a4456"
  # iso_storage_pool = "local"
  unmount_iso = true

  scsi_controller = "virtio-scsi-pci"
  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = true
  }
  network_adapters {
    bridge = "vmbr1"
    model  = "virtio"
  }
  disks {
    type              = "scsi"
    storage_pool      = var.proxmox_storage
    storage_pool_type = var.proxmox_storage_type
    format            = "raw"
    disk_size         = "5G"
    cache_mode        = "writethrough"
  }

  cpu_type = "host"
  memory   = 3072
  # vga {
  #   type = "serial0"
  # }
  serials = ["socket"]

  ssh_username = "root"
  ssh_password = "packer"
  ssh_timeout  = "15m"
  qemu_agent   = true

  ssh_bastion_host       = var.proxmox_host
  ssh_bastion_username   = "root"
  ssh_bastion_agent_auth = true

  template_name        = "talos"
  template_description = "Talos system disk, version ${var.talos_version}"

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
    source      = "nocloud-amd64.raw.xz"
    destination = "/tmp/talos.raw.xz"
  }
  provisioner "shell" {
    inline = [
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}
