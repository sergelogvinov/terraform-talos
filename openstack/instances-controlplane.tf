
locals {
  controlplane_prefix = "controlplane"

  controlplanes = { for k in flatten([
    for region in local.regions : [
      for inx in range(lookup(try(var.controlplane[region], {}), "count", 0)) : {
        name : "${local.controlplane_prefix}-${lower(region)}-${1 + inx}"
        region : region
        ip  = cidrhost(local.network_public[region].cidr, 11 + inx)
        vip = cidrhost(local.network_public[region].cidr, 5)
        type : lookup(try(var.controlplane[region], {}), "type", "d2-2")
      }
    ]
  ]) : k.name => k }

  controlplane_lbv4 = { for region in local.regions :
    region => cidrhost(local.network_public[region].cidr, 5) if lookup(try(var.controlplane[region], {}), "count", 0) != 0
  }
}

resource "openstack_compute_servergroup_v2" "controlplane" {
  for_each = { for idx, name in local.regions : name => idx }
  region   = each.key
  name     = "controlplane"
  policies = ["anti-affinity"]
}

resource "openstack_networking_port_v2" "controlplane" {
  for_each       = local.controlplanes
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

resource "openstack_networking_port_v2" "controlplane_public" {
  for_each           = local.controlplanes
  region             = each.value.region
  name               = lower(each.value.name)
  network_id         = local.network_external[each.value.region].id
  admin_state_up     = true
  security_group_ids = [local.network_secgroup[each.value.region].common, local.network_secgroup[each.value.region].controlplane]
}

resource "openstack_compute_instance_v2" "controlplane" {
  for_each    = local.controlplanes
  region      = each.value.region
  name        = each.value.name
  flavor_name = each.value.type
  tags        = concat(var.tags, ["infra"])
  image_id    = data.openstack_images_image_v2.talos[each.value.region].id

  scheduler_hints {
    group = openstack_compute_servergroup_v2.controlplane[each.value.region].id
  }

  stop_before_destroy = true

  network {
    port = openstack_networking_port_v2.controlplane_public[each.key].id
  }
  network {
    port = openstack_networking_port_v2.controlplane[each.key].id
  }

  lifecycle {
    ignore_changes = [flavor_name, image_id, scheduler_hints, user_data]
  }
}

locals {
  ips      = flatten([for k, v in openstack_networking_port_v2.controlplane : v.all_fixed_ips])
  endpoint = flatten([for k, v in openstack_networking_port_v2.controlplane_public : v.all_fixed_ips])
}

resource "local_sensitive_file" "controlplane" {
  for_each = local.controlplanes

  content = templatefile("${path.module}/templates/controlplane.yaml.tpl",
    merge(var.kubernetes, {
      name   = each.value.name
      labels = "topology.kubernetes.io/region=${each.value.region}"
      certSANs = flatten([
        var.kubernetes["apiDomain"],
      ])

      routes         = "\n${join("\n", formatlist("          - network: %s", flatten([for zone in local.regions : local.network_subnets[zone]])))}"
      ipv4_local     = each.value.ip
      ipv4_local_vip = each.value.vip
      ipv4           = one([for ip in openstack_networking_port_v2.controlplane_public[each.key].all_fixed_ips : ip if length(split(".", ip)) > 1])
      ipv6           = one([for ip in openstack_networking_port_v2.controlplane_public[each.key].all_fixed_ips : ip if length(split(":", ip)) > 1])
      nodeSubnets    = split(",", local.network_public[each.value.region].cidr)

      occm = templatefile("${path.module}/templates/openstack-cloud-controller-manager.conf.tpl", {
        username            = var.ccm_username
        password            = var.ccm_password
        region              = each.value.region
        auth                = local.openstack_auth_url
        project_id          = local.project_id
        project_domain_id   = local.project_domain_id
        network_public_name = local.network_external[each.value.region].name
      })
    })
  )
  filename        = "_cfgs/${each.value.name}.yaml"
  file_permission = "0600"
}

locals {
  bootstrap = [for k, v in local.controlplanes : "talosctl apply-config --insecure --nodes ${
    one([for ip in openstack_networking_port_v2.controlplane_public[k].all_fixed_ips : ip if length(split(".", ip)) > 1])
  } --config-patch @${local_sensitive_file.controlplane[k].filename} --file _cfgs/controlplane.yaml"]
}

output "bootstrap" {
  value = local.bootstrap
}

# locals {
#   lbv4s    = compact([for c in module.controlplane : c.controlplane_lb])
# }
