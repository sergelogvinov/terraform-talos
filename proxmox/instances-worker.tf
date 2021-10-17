
resource "null_resource" "worker_machineconfig" {
  count = lookup(var.worker, "count", 0)
  connection {
    type = "ssh"
    user = "root"
    host = var.proxmox_host
  }

  provisioner "file" {
    # content     = file("init.yaml")
    source      = "worker.yaml"
    destination = "/var/lib/vz/snippets/worker-${count.index + 1}.yml"
  }
}

resource "proxmox_vm_qemu" "worker" {
  count       = lookup(var.worker, "count", 0)
  name        = "worker-${count.index + 1}"
  target_node = var.proxmox_nodename
  clone       = var.proxmox_image

  # preprovision           = false
  define_connection_info  = false
  os_type                 = "ubuntu"
  ipconfig0               = "ip=${cidrhost(var.vpc_main_cidr, 21 + count.index)}/24,gw=${local.gwv4}"
  cicustom                = "user=local:snippets/worker-${count.index + 1}.yml"
  cloudinit_cdrom_storage = var.proxmox_storage

  onboot  = false
  cpu     = "host,flags=+aes"
  cores   = 1
  sockets = 1
  memory  = 1024
  scsihw  = "virtio-scsi-pci"

  vga {
    memory = 0
    type   = "serial0"
  }
  serial {
    id   = 0
    type = "socket"
  }

  network {
    model    = "virtio"
    bridge   = var.proxmox_bridge
    firewall = true
  }

  boot = "order=scsi0"
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
      network,
      desc,
      define_connection_info,
    ]
  }

  depends_on = [null_resource.worker_machineconfig]
}
