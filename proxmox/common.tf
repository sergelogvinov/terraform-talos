
data "proxmox_virtual_environment_node" "node" {
  for_each  = { for inx, zone in local.zones : zone => inx if lookup(try(var.instances[zone], {}), "enabled", false) }
  node_name = each.key
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

resource "local_sensitive_file" "talos_values" {
  content = templatefile("${path.module}/templates/talos-values.yaml.tpl",
    merge(local.kubernetes, try(var.instances["all"], {}))
  )
  filename        = "_cfgs/talos-values.yaml"
  file_permission = "0600"
}

module "template" {
  for_each = { for inx, zone in local.zones : zone => inx if lookup(try(var.instances[zone], {}), "enabled", false) }

  # source = "../../../sergelogvinov/terraform-proxmox-template-talos"
  source             = "github.com/sergelogvinov/terraform-proxmox-template-talos"
  node               = each.key
  template_id        = each.value + 1000
  template_datastore = "system"

  template_network_dns = ["1.1.1.1", "2001:4860:4860::8888"]
  template_network = {
    "vmbr0" = {
      firewall = true
      ip6      = lookup(try(var.nodes[each.key], {}), "ip6", "fe80::/64")
      gw6      = lookup(try(var.nodes[each.key], {}), "gw6", "fe80::1")
    }
    "vmbr1" = {
      ip6 = var.vpc_main_cidr[1]
      ip4 = var.vpc_main_cidr[0]
      gw4 = cidrhost(local.subnets[each.key], 0)
    }
  }
  template_userdata = templatefile("${path.module}/templates/common.yaml.tpl",
    merge(local.kubernetes, try(var.instances["all"], {}), {
      labels      = "node-pool=common,karpenter.sh/nodepool=default"
      nodeSubnets = [var.vpc_main_cidr[0], var.vpc_main_cidr[1]]
      lbv4        = local.lbv4
      kernelArgs  = []
  }))
}
