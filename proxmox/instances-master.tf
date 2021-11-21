
resource "null_resource" "controlplane_machineconfig" {
  count = lookup(var.controlplane, "count", 0)
  connection {
    type = "ssh"
    user = "root"
    host = var.proxmox_host
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/controlplane.yaml",
      merge(var.kubernetes, {
        name        = "master-${count.index + 1}"
        type        = "controlplane"
        ipv4_local  = "192.168.10.11"
        ipv4_vip    = "192.168.10.10"
        nodeSubnets = "${var.vpc_main_cidr}"
      })
    )

    destination = "/var/lib/vz/snippets/master-${count.index + 1}.yml"
  }
}

resource "proxmox_vm_qemu" "controlplane" {
  count       = lookup(var.controlplane, "count", 0)
  name        = "master-${count.index + 1}"
  target_node = var.proxmox_nodename
  clone       = var.proxmox_image

  # preprovision           = false
  define_connection_info  = false
  os_type                 = "ubuntu"
  ipconfig0               = "ip=${cidrhost(var.vpc_main_cidr, 11 + count.index)}/24,gw=${local.gwv4}"
  cicustom                = "user=local:snippets/master-${count.index + 1}.yml"
  cloudinit_cdrom_storage = var.proxmox_storage

  onboot  = false
  cpu     = "host,flags=+aes"
  cores   = 2
  sockets = 1
  memory  = 2048
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
    firewall = false
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
      desc,
      define_connection_info,
    ]
  }

  depends_on = [null_resource.controlplane_machineconfig]
}
