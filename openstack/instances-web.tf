
resource "openstack_compute_servergroup_v2" "web" {
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key
  name     = "web"
  policies = ["soft-anti-affinity"]
}

locals {
  web_prefix = "web"

  web = { for k in flatten([
    for region in local.regions : [
      for inx in range(lookup(try(var.instances[region], {}), "web_count", 0)) : {
        name : "${local.web_prefix}-${lower(region)}-${1 + inx}"
        region : region
        ip   = cidrhost(local.network_public[region].cidr, 21 + inx)
        cidr = local.network_public[region].cidr
        lbv4 = try(local.controlplane_lbv4[region], one([for ip in local.controlplane_lbv4 : ip]))
        type : lookup(try(var.instances[region], {}), "web_type", "d2-2")
      }
    ]
  ]) : k.name => k }
}

resource "openstack_networking_port_v2" "web" {
  for_each       = local.web
  region         = each.value.region
  name           = lower(each.value.name)
  network_id     = local.network_public[each.value.region].network_id
  admin_state_up = true

  port_security_enabled = false
  fixed_ip {
    subnet_id  = local.network_public[each.value.region].subnet_id
    ip_address = each.value.ip
  }

  lifecycle {
    ignore_changes = [port_security_enabled]
  }
}

resource "openstack_networking_port_v2" "web_public" {
  for_each           = local.web
  region             = each.value.region
  name               = lower(each.value.name)
  admin_state_up     = true
  network_id         = local.network_external[each.value.region].id
  security_group_ids = [local.network_secgroup[each.value.region].common, local.network_secgroup[each.value.region].web]
}

resource "openstack_compute_instance_v2" "web" {
  for_each    = local.web
  region      = each.value.region
  name        = each.value.name
  flavor_name = each.value.type
  tags        = concat(var.tags, ["web"])
  image_id    = data.openstack_images_image_v2.talos[each.value.region].id

  scheduler_hints {
    group = openstack_compute_servergroup_v2.web[each.value.region].id
  }
  network {
    port = openstack_networking_port_v2.web_public[each.key].id
  }
  network {
    port = openstack_networking_port_v2.web[each.key].id
  }

  user_data = templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, {
      name        = each.value.name
      labels      = "topology.kubernetes.io/region=${each.value.region},project.io/node-pool=web"
      iface       = "eth1"
      nodeSubnets = each.value.cidr
      lbv4        = each.value.lbv4
      routes      = "\n${join("\n", formatlist("          - network: %s", flatten([for zone in local.regions : local.network_subnets[zone]])))}"
    })
  )

  stop_before_destroy = true
  lifecycle {
    ignore_changes = [flavor_name, image_id, scheduler_hints, user_data]
  }
}

locals {
  web_endpoint = flatten([for k, v in openstack_networking_port_v2.web_public : v.all_fixed_ips])
}

resource "local_file" "worker" {
  for_each = local.web

  content = templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, {
      name        = each.value.name
      labels      = "topology.kubernetes.io/region=${each.value.region},project.io/node-pool=web"
      iface       = "eth1"
      nodeSubnets = each.value.cidr
      lbv4        = each.value.lbv4
      routes      = "\n${join("\n", formatlist("          - network: %s", flatten([for zone in local.regions : local.network_subnets[zone]])))}"
    })
  )

  filename        = "_cfgs/${each.value.name}.yaml"
  file_permission = "0600"
}
