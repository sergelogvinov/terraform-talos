
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
  url                     = "https://factory.talos.dev/image/14e9b0100f05654bedf19b92313cdc224cbff52879193d24f3741f1da4a3cbb1/v${var.release}/nocloud-amd64.raw.xz"
}

resource "proxmox_virtual_environment_file" "machineconfig" {
  for_each     = { for inx, zone in local.zones : zone => inx if lookup(try(var.instances[zone], {}), "enabled", false) }
  node_name    = each.key
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("${path.module}/templates/common.yaml.tpl",
      merge(local.kubernetes, try(var.instances["all"], {}), {
        labels      = "node-pool=common,karpenter.sh/nodepool=default"
        nodeSubnets = [var.vpc_main_cidr[0], var.vpc_main_cidr[1]]
        lbv4        = local.lbv4
        kernelArgs  = []
    }))
    file_name = "common.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "template" {
  for_each    = { for inx, zone in local.zones : zone => inx if lookup(try(var.instances[zone], {}), "enabled", false) }
  name        = "talos"
  node_name   = each.key
  vm_id       = each.value + 1000
  on_boot     = false
  template    = true
  description = "Talos ${var.release} template"
  tags        = ["talos"]

  tablet_device = false

  machine = "q35"
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
    datastore_id = "system"
    interface    = "scsi0"
    ssd          = true
    iothread     = true
    cache        = "none"
    size         = 3
    file_format  = "raw"
  }

  network_device {
    bridge   = "vmbr0"
    mtu      = 1500
    firewall = true
  }
  network_device {
    bridge   = "vmbr1"
    mtu      = 1400
    firewall = false
  }

  operating_system {
    type = "l26"
  }

  initialization {
    dns {
      servers = ["1.1.1.1", "2001:4860:4860::8888"]
    }
    ip_config {
      ipv6 {
        address = lookup(try(var.nodes[each.key], {}), "ip6", "fe80::/64")
        gateway = lookup(try(var.nodes[each.key], {}), "gw6", "fe80::1")
      }
    }
    ip_config {
      ipv4 {
        address = var.vpc_main_cidr[0]
        gateway = cidrhost(local.subnets[each.key], 0)
      }
      ipv6 {
        address = var.vpc_main_cidr[1]
      }
    }

    datastore_id      = "system"
    user_data_file_id = proxmox_virtual_environment_file.machineconfig[each.key].id
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
