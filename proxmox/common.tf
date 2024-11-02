
locals {
  cpu_numa = {
    for k, v in var.nodes : k => [for i in lookup(v, "cpu", "") :
      flatten([for r in split(",", i) : (strcontains(r, "-") ? range(split("-", r)[0], split("-", r)[1] + 1, 1) : [r])])
    ]
  }

  cpus = { for k, v in local.cpu_numa : k =>
    flatten([for numa in v : flatten([for r in range(length(numa) / 2) : [numa[r], numa[r + length(numa) / 2]]])])
  }
}

data "proxmox_virtual_environment_node" "node" {
  for_each  = { for inx, zone in local.zones : zone => inx if lookup(try(var.instances[zone], {}), "enabled", false) }
  node_name = each.key
}

resource "proxmox_virtual_environment_download_file" "talos" {
  for_each     = { for inx, zone in local.zones : zone => inx if lookup(try(var.instances[zone], {}), "enabled", false) }
  node_name    = each.key
  content_type = "iso"
  datastore_id = "local"
  file_name    = "talos.raw.xz.img"
  overwrite    = false

  # Hash: 376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba customization: {}
  # Hash: 14e9b0100f05654bedf19b92313cdc224cbff52879193d24f3741f1da4a3cbb1 customization: siderolabs/binfmt-misc
  decompression_algorithm = "zst"
  url                     = "https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v${var.release}/nocloud-amd64.raw.xz"
}

resource "proxmox_virtual_environment_vm" "template" {
  for_each    = { for inx, zone in local.zones : zone => inx if lookup(try(var.instances[zone], {}), "enabled", false) }
  name        = "talos"
  node_name   = each.key
  vm_id       = each.value + 1000
  on_boot     = false
  template    = true
  description = "Talos ${var.release} template"

  tablet_device = false

  machine = "pc"
  cpu {
    architecture = "x86_64"
    cores        = 1
    sockets      = 1
    numa         = true
    type         = "host"
  }

  scsi_hardware = "virtio-scsi-single"
  disk {
    file_id      = proxmox_virtual_environment_download_file.talos[each.key].id
    datastore_id = "local"
    interface    = "scsi0"
    ssd          = true
    iothread     = true
    cache        = "none"
    size         = 2
    file_format  = "raw"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
  vga {
    type = "serial0"
  }

  lifecycle {
    ignore_changes = [
      ipv4_addresses,
      ipv6_addresses,
      network_interface_names,
    ]
  }
}
