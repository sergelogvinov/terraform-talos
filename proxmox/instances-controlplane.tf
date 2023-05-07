
locals {
  controlplane_prefix = "controlplane"
  controlplanes = { for k in flatten([
    for zone in local.zones : [
      for inx in range(lookup(try(var.controlplane[zone], {}), "count", 0)) : {
        id : lookup(try(var.controlplane[zone], {}), "id", 9000) + inx
        name : "${local.controlplane_prefix}-${lower(substr(zone, -1, -1))}${1 + inx}"
        zone : zone
        node_name : zone
        cpu : lookup(try(var.controlplane[zone], {}), "cpu", 1)
        mem : lookup(try(var.controlplane[zone], {}), "mem", 2048)
        ip0 : lookup(try(var.controlplane[zone], {}), "ip0", "ip6=auto")
        ipv4 : "${cidrhost(local.controlplane_subnet, index(local.zones, zone) + inx)}/24"
        gwv4 : local.gwv4
      }
    ]
  ]) : k.name => k }
}

resource "null_resource" "controlplane_metadata" {
  for_each = local.controlplanes
  connection {
    type = "ssh"
    user = "root"
    host = "${each.value.node_name}.${var.proxmox_domain}"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/metadata.yaml", {
      hostname : each.value.name,
      id : each.value.id,
      providerID : "proxmox://${var.region}/${each.value.id}",
      type : "${each.value.cpu}VCPU-${floor(each.value.mem / 1024)}GB",
      zone : each.value.zone,
      region : var.region,
    })
    destination = "/var/lib/vz/snippets/${each.value.name}.metadata.yaml"
  }

  triggers = {
    params = join(",", [for k, v in local.controlplanes[each.key] : "${k}-${v}"])
  }
}

resource "proxmox_vm_qemu" "controlplane" {
  for_each    = local.controlplanes
  name        = each.value.name
  vmid        = each.value.id
  target_node = each.value.node_name
  clone       = var.proxmox_image

  agent                   = 0
  define_connection_info  = false
  os_type                 = "ubuntu"
  qemu_os                 = "l26"
  ipconfig0               = each.value.ip0
  ipconfig1               = "ip=${each.value.ipv4},gw=${each.value.gwv4}"
  cicustom                = "meta=local:snippets/${each.value.name}.metadata.yaml"
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

  depends_on = [null_resource.controlplane_metadata]
}

resource "local_sensitive_file" "controlplane" {
  for_each = local.controlplanes
  content = templatefile("${path.module}/templates/controlplane.yaml.tpl",
    merge(var.kubernetes, {
      name        = each.value.name
      ipv4_vip    = local.ipv4_vip
      nodeSubnets = local.controlplane_subnet
      clusters = yamlencode({
        clusters = [
          {
            token_id     = var.proxmox_token_id
            token_secret = var.proxmox_token_secret
            url          = "https://${var.proxmox_host}:8006/api2/json"
            region       = var.region
          },
        ]
      })
    })
  )
  filename        = "_cfgs/${each.value.name}.yaml"
  file_permission = "0600"
}

resource "null_resource" "controlplane" {
  for_each = local.controlplanes
  provisioner "local-exec" {
    command = "echo talosctl apply-config --insecure --nodes ${split("/", each.value.ipv4)[0]} --config-patch @_cfgs/${each.value.name}.yaml --file _cfgs/controlplane.yaml"
  }
  depends_on = [proxmox_vm_qemu.controlplane, local_sensitive_file.controlplane]
}
