
locals {
  controlplane_prefix = "controlplane"
  controlplane_labels = "node-pool=controlplane"

  controlplanes = { for k in flatten([
    for zone in local.zones : [
      for inx in range(lookup(try(var.controlplane[zone], {}), "count", 0)) : {
        id : lookup(try(var.controlplane[zone], {}), "id", 9000) + inx
        name : "${local.controlplane_prefix}-${format("%02d", index(local.zones, zone))}${format("%x", 10 + inx)}"
        zone : zone
        cpu : lookup(try(var.controlplane[zone], {}), "cpu", 1)
        mem : lookup(try(var.controlplane[zone], {}), "mem", 2048)

        hvv4 = cidrhost(local.subnets[zone], 0)
        ipv4 : cidrhost(local.subnets[zone], -(2 + inx))
        gwv4 : cidrhost(local.subnets[zone], 0)

        ipv6ula : cidrhost(cidrsubnet(var.vpc_main_cidr[1], 16, index(local.zones, zone)), 512 + lookup(try(var.controlplane[zone], {}), "id", 9000) + inx)
        ipv6 : cidrhost(cidrsubnet(lookup(try(var.nodes[zone], {}), "ip6", "fe80::/64"), 16, index(local.zones, zone)), 512 + lookup(try(var.controlplane[zone], {}), "id", 9000) + inx)
        gwv6 : lookup(try(var.nodes[zone], {}), "gw6", "fe80::1")
      }
    ]
  ]) : k.name => k }

  controlplane_v4 = [for ip in local.controlplanes : ip.ipv4]
  controlplane_v6 = [for ip in local.controlplanes : ip.ipv6]
}

output "controlplanes" {
  value = local.controlplanes
}

resource "proxmox_virtual_environment_file" "controlplane_metadata" {
  for_each     = local.controlplanes
  node_name    = each.value.zone
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("${path.module}/templates/metadata.yaml", {
      hostname : each.value.name,
      id : each.value.id,
      providerID : "proxmox://${var.region}/${each.value.id}",
      type : "${each.value.cpu}VCPU-${floor(each.value.mem / 1024)}GB",
      zone : each.value.zone,
      region : var.region,
    })
    file_name = "${each.value.name}.metadata.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "controlplane" {
  for_each            = local.controlplanes
  name                = each.value.name
  node_name           = each.value.zone
  vm_id               = each.value.id
  pool_id             = proxmox_virtual_environment_pool.pool.pool_id
  reboot_after_update = false
  description         = "Talos controlplane at ${var.region}"

  machine = "q35"
  cpu {
    architecture = "x86_64"
    cores        = each.value.cpu
    sockets      = 1
    numa         = true
    type         = "host"
  }
  memory {
    dedicated = each.value.mem
  }

  scsi_hardware = "virtio-scsi-single"
  disk {
    datastore_id = var.nodes[each.value.zone].storage
    interface    = "scsi0"
    iothread     = true
    cache        = "none"
    size         = 50
    ssd          = true
    file_format  = "raw"
  }
  clone {
    vm_id = proxmox_virtual_environment_vm.template[each.value.zone].id
  }

  smbios {
    serial = "h=${each.value.name};i=${each.value.id}"
  }
  initialization {
    dns {
      servers = ["1.1.1.1", "2001:4860:4860::8888", each.value.hvv4]
    }
    ip_config {
      ipv6 {
        address = "${each.value.ipv6}/64"
        gateway = each.value.gwv6
      }
    }
    ip_config {
      ipv4 {
        address = "${each.value.ipv4}/24"
        gateway = each.value.hvv4
      }
      ipv6 {
        address = "${each.value.ipv6ula}/64"
      }
    }

    datastore_id      = var.nodes[each.value.zone].storage
    meta_data_file_id = proxmox_virtual_environment_file.controlplane_metadata[each.key].id
  }

  network_device {
    bridge      = "vmbr0"
    queues      = each.value.cpu
    mtu         = 1500
    mac_address = "32:90:${join(":", formatlist("%02X", split(".", each.value.ipv4)))}"
    firewall    = true
  }
  network_device {
    bridge   = "vmbr1"
    queues   = each.value.cpu
    mtu      = 1400
    firewall = false
  }

  operating_system {
    type = "l26"
  }
  tpm_state {
    version      = "v2.0"
    datastore_id = var.nodes[each.value.zone].storage
  }

  serial_device {}
  vga {
    type = "serial0"
  }

  lifecycle {
    ignore_changes = [
      started,
      ipv4_addresses,
      ipv6_addresses,
      network_interface_names,
      initialization,
      cpu,
      memory,
      disk,
      clone,
      network_device,
    ]
  }

  tags       = [local.kubernetes["clusterName"]]
  depends_on = [proxmox_virtual_environment_file.controlplane_metadata]
}

resource "proxmox_virtual_environment_firewall_options" "controlplane" {
  for_each  = lookup(var.security_groups, "controlplane", "") == "" ? {} : local.controlplanes
  node_name = each.value.zone
  vm_id     = each.value.id
  enabled   = true

  dhcp          = false
  ipfilter      = false
  log_level_in  = "nolog"
  log_level_out = "nolog"
  macfilter     = false
  ndp           = true
  input_policy  = "DROP"
  output_policy = "ACCEPT"
  radv          = false

  depends_on = [proxmox_virtual_environment_vm.controlplane]
}

resource "proxmox_virtual_environment_firewall_rules" "controlplane" {
  for_each  = lookup(var.security_groups, "controlplane", "") == "" ? {} : local.controlplanes
  node_name = each.value.zone
  vm_id     = each.value.id

  dynamic "rule" {
    for_each = { for idx, rule in split(",", var.security_groups["controlplane"]) : idx => rule }
    content {
      enabled        = true
      security_group = rule.value
    }
  }

  depends_on = [proxmox_virtual_environment_vm.controlplane, proxmox_virtual_environment_firewall_options.controlplane]
}

resource "local_sensitive_file" "controlplane" {
  for_each = local.controlplanes
  content = templatefile("${path.module}/templates/controlplane.yaml.tpl",
    merge(local.kubernetes, try(var.instances["all"], {}), {
      name        = each.value.name
      labels      = local.controlplane_labels
      nodeSubnets = [local.subnets[each.value.zone], var.vpc_main_cidr[1]]
      lbv4        = local.lbv4
      ipv4        = each.value.ipv4
      gwv4        = each.value.gwv4
      ipv6        = "${each.value.ipv6}/64"
      gwv6        = each.value.gwv6
      clusters = yamlencode({
        "clusters" : [{
          "url" : "https://${each.value.hvv4}:8006/api2/json",
          "insecure" : true,
          "token_id" : split("=", local.proxmox_token_ccm)[0],
          "token_secret" : split("=", local.proxmox_token_ccm)[1],
          "region" : var.region,
        }]
      })
    })
  )
  filename        = "_cfgs/${each.value.name}.yaml"
  file_permission = "0600"
}

resource "local_sensitive_file" "csi" {
  content = yamlencode({
    "config" : {
      "clusters" : [{
        "url" : "https://${var.proxmox_host}:8006/api2/json",
        "insecure" : true,
        "token_id" : split("=", local.proxmox_token_csi)[0],
        "token_secret" : split("=", local.proxmox_token_csi)[1],
        "region" : var.region,
      }]
    }
  })
  filename        = "vars/secrets.proxmox.yaml"
  file_permission = "0600"
}

locals {
  controlplane_config = { for k, v in local.controlplanes : k => "talosctl apply-config --insecure --nodes ${v.ipv6} --config-patch @_cfgs/${v.name}.yaml --file _cfgs/controlplane.yaml" }
}

output "controlplane_config" {
  value = local.controlplane_config
}
