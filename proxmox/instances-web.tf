
locals {
  web_prefix = "web"
  webs = { for k in flatten([
    for zone in local.zones : [
      for inx in range(lookup(try(var.instances[zone], {}), "web_count", 0)) : {
        id : lookup(try(var.instances[zone], {}), "web_id", 9000) + inx
        name : "${local.web_prefix}-${lower(substr(zone, -1, -1))}${1 + inx}"
        zone : zone
        node_name : zone
        cpu : lookup(try(var.instances[zone], {}), "web_cpu", 1)
        mem : lookup(try(var.instances[zone], {}), "web_mem", 2048)
        ipv4 : "${cidrhost(local.subnets[zone], inx)}/24"
        gwv4 : local.gwv4
      }
    ]
  ]) : k.name => k }
}

resource "null_resource" "web_machineconfig" {
  for_each = { for k, v in var.instances : k => v if lookup(try(var.instances[k], {}), "web_count", 0) > 0 }
  connection {
    type = "ssh"
    user = "root"
    host = "${each.key}.${var.proxmox_domain}"
  }

  provisioner "file" {
    source      = "${path.module}/_cfgs/worker.yaml"
    destination = "/var/lib/vz/snippets/${local.web_prefix}.yaml"
  }

  triggers = {
    params = filemd5("${path.module}/_cfgs/worker.yaml")
  }
}

resource "null_resource" "web_metadata" {
  for_each = local.webs
  connection {
    type = "ssh"
    user = "root"
    host = "${each.value.node_name}.${var.proxmox_domain}"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/metadata.yaml", {
      hostname : each.value.name,
      id : each.value.id,
      type : "qemu",
      zone : each.value.zone,
      region : var.region,
    })
    destination = "/var/lib/vz/snippets/${each.value.name}.metadata.yaml"
  }

  triggers = {
    params = join(",", [for k, v in local.webs[each.key] : "${k}-${v}"])
  }
}

resource "proxmox_vm_qemu" "web" {
  for_each    = local.webs
  name        = each.value.name
  vmid        = each.value.id
  target_node = each.value.node_name
  clone       = var.proxmox_image

  agent                   = 0
  define_connection_info  = false
  os_type                 = "ubuntu"
  qemu_os                 = "l26"
  ipconfig0               = "ip6=auto"
  ipconfig1               = "ip=${each.value.ipv4},gw=${each.value.gwv4}"
  cicustom                = "user=local:snippets/${local.web_prefix}.yaml,meta=local:snippets/${each.value.name}.metadata.yaml"
  cloudinit_cdrom_storage = var.proxmox_storage

  onboot  = false
  cpu     = "host,flags=+aes"
  sockets = 1
  cores   = each.value.cpu
  memory  = each.value.mem
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
    bridge   = "vmbr0"
    firewall = true
  }
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  boot = "order=scsi0"
  disk {
    type    = "scsi"
    storage = var.proxmox_storage
    size    = "32G"
    cache   = "writethrough"
    ssd     = 1
    backup  = false
  }

  lifecycle {
    ignore_changes = [
      boot,
      network,
      desc,
      numa,
      agent,
      ipconfig0,
      ipconfig1,
      define_connection_info,
    ]
  }

  depends_on = [null_resource.web_machineconfig, null_resource.web_metadata]
}
