
locals {
  worker_prefix = "worker"
  worker_labels = "node-pool=worker"

  workers = { for k in flatten([
    for zone in local.zones : [
      for inx in range(lookup(try(var.instances[zone], {}), "worker_count", 0)) : {
        id : lookup(try(var.instances[zone], {}), "worker_id", 9000) + inx
        name : "${local.worker_prefix}-${format("%02d", index(local.zones, zone))}${format("%x", 10 + inx)}"
        zone : zone
        node_name : zone
        cpu : lookup(try(var.instances[zone], {}), "worker_cpu", 1)
        cpus : join(",", slice(
          flatten(local.cpus[zone]),
          (inx + 2) * lookup(try(var.instances[zone], {}), "worker_cpu", 1), (inx + 3) * lookup(try(var.instances[zone], {}), "worker_cpu", 1)
        ))
        numas : [0] # [2 + inx]
        mem : lookup(try(var.instances[zone], {}), "worker_mem", 2048)

        hvv4 = cidrhost(local.subnets[zone], 0)
        ipv4 : cidrhost(local.subnets[zone], 7 + inx)
        gwv4 : cidrhost(local.subnets[zone], 0)

        ipv6ula : cidrhost(cidrsubnet(var.vpc_main_cidr[1], 16, index(local.zones, zone)), 384 + lookup(try(var.instances[zone], {}), "worker_id", 9000) + inx)
        ipv6 : cidrhost(cidrsubnet(lookup(try(var.nodes[zone], {}), "ip6", "fe80::/64"), 16, 1 + index(local.zones, zone)), 384 + lookup(try(var.instances[zone], {}), "worker_id", 9000) + inx)
        gwv6 : lookup(try(var.nodes[zone], {}), "gw6", "fe80::1")
      }
    ]
  ]) : k.name => k }
}

resource "proxmox_virtual_environment_file" "worker_machineconfig" {
  for_each     = local.workers
  node_name    = each.value.node_name
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("${path.module}/templates/${lookup(var.instances[each.value.zone], "worker_template", "worker.yaml.tpl")}",
      merge(local.kubernetes, try(var.instances["all"], {}), {
        labels      = join(",", [local.worker_labels, lookup(var.instances[each.value.zone], "worker_labels", "")])
        nodeSubnets = [local.subnets[each.value.zone], var.vpc_main_cidr[1]]
        lbv4        = local.lbv4
        ipv4        = each.value.ipv4
        gwv4        = each.value.gwv4
        hvv4        = each.value.hvv4
        ipv6        = "${each.value.ipv6}/64"
        gwv6        = each.value.gwv6
        kernelArgs  = []
    }))
    file_name = "${each.value.name}.yaml"
  }
}

resource "proxmox_virtual_environment_file" "worker_metadata" {
  for_each     = local.workers
  node_name    = each.value.node_name
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

resource "proxmox_virtual_environment_vm" "worker" {
  for_each    = local.workers
  name        = each.value.name
  node_name   = each.value.node_name
  vm_id       = each.value.id
  description = "Talos worker node"

  startup {
    order    = 7
    up_delay = 15
  }

  machine = "pc"
  cpu {
    architecture = "x86_64"
    cores        = each.value.cpu
    affinity     = each.value.cpus
    sockets      = 1
    numa         = true
    type         = "host"
  }
  memory {
    dedicated = each.value.mem
    # hugepages      = "1024"
    # keep_hugepages = true
  }
  dynamic "numa" {
    for_each = { for idx, numa in each.value.numas : numa => {
      device = "numa${idx}"
      cpus   = "0-${each.value.cpu - 1}"
      mem    = each.value.mem
    } }
    content {
      device    = numa.value.device
      cpus      = numa.value.cpus
      hostnodes = numa.key
      memory    = numa.value.mem
      policy    = "bind"
    }
  }

  scsi_hardware = "virtio-scsi-single"
  disk {
    datastore_id = lookup(try(var.nodes[each.value.zone], {}), "storage", "local")
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    cache        = "none"
    size         = 32
    file_format  = "raw"
  }
  clone {
    vm_id = proxmox_virtual_environment_vm.template[each.value.zone].id
  }

  initialization {
    dns {
      servers = [each.value.gwv4, "2001:4860:4860::8888"]
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

    datastore_id      = "local"
    meta_data_file_id = proxmox_virtual_environment_file.worker_metadata[each.key].id
    user_data_file_id = proxmox_virtual_environment_file.worker_machineconfig[each.key].id
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

  serial_device {}
  vga {
    type = "serial0"
  }

  lifecycle {
    ignore_changes = [
      started,
      clone,
      ipv4_addresses,
      ipv6_addresses,
      network_interface_names,
      initialization,
      disk,
      # memory,
      # numa,
    ]
  }

  tags       = [local.kubernetes["clusterName"]]
  depends_on = [proxmox_virtual_environment_file.worker_machineconfig]
}

resource "proxmox_virtual_environment_firewall_options" "worker" {
  for_each  = local.workers
  node_name = each.value.node_name
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

  depends_on = [proxmox_virtual_environment_vm.worker]
}

resource "proxmox_virtual_environment_firewall_rules" "worker" {
  for_each  = { for k, v in local.workers : k => v if lookup(try(var.instances[v.zone], {}), "worker_sg", "") != "" }
  node_name = each.value.node_name
  vm_id     = each.value.id

  rule {
    enabled        = true
    security_group = lookup(var.instances[each.value.zone], "worker_sg")
  }

  depends_on = [proxmox_virtual_environment_vm.worker, proxmox_virtual_environment_firewall_options.worker]
}
