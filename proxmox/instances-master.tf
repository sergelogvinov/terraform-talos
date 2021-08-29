
locals {
  gwv4 = cidrhost(var.vpc_main_cidr, -3)
}

resource "null_resource" "cloud_init_config_files" {
  count = lookup(var.controlplane, "count", 0)
  connection {
    type = "ssh"
    user = "root"
    host = var.proxmox_host
  }

  provisioner "file" {
    # content     = ""
    source      = "init.yaml"
    destination = "/var/lib/vz/snippets/master-${count.index + 1}.yml"
  }
}

resource "proxmox_vm_qemu" "controlplane" {
  count       = lookup(var.controlplane, "count", 0)
  name        = "master-${count.index + 1}"
  target_node = var.proxmox_nodename
  clone       = "talos"

  # preprovision           = false
  define_connection_info  = false
  os_type                 = "ubuntu"
  ipconfig0               = "ip=${cidrhost(var.vpc_main_cidr, 11 + count.index)}/24,gw=${local.gwv4}"
  cicustom                = "user=local:snippets/master-${count.index + 1}.yml"
  cloudinit_cdrom_storage = var.proxmox_storage

  onboot  = false
  bios    = "ovmf"
  cpu     = "host,flags=+aes"
  cores   = 2
  sockets = 1
  memory  = 2048
  scsihw  = "virtio-scsi-pci"

  vga {
    type = "serial0"
  }
  serial {
    id   = 0
    type = "socket"
  }

  network {
    model  = "virtio"
    bridge = var.proxmox_bridge
  }

  boot = "order=scsi0;net0"
  disk {
    type    = "scsi"
    storage = var.proxmox_storage
    size    = "16G"
    cache   = "writethrough"
    ssd     = 1
    backup  = 0
  }

  lifecycle {
    ignore_changes = [
      desc,
    ]
  }

  depends_on = [null_resource.cloud_init_config_files]
}
