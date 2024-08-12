
resource "scaleway_instance_placement_group" "controlplane" {
  name        = "controlplane"
  policy_type = "max_availability"
  policy_mode = "enforced"
}

resource "scaleway_instance_ip" "controlplane_v4" {
  count = lookup(var.controlplane, "count", 0)
  type  = "routed_ipv4"
}

resource "scaleway_instance_ip" "controlplane_v6" {
  count = lookup(var.controlplane, "count", 0)
  type  = "routed_ipv6"
}

resource "scaleway_ipam_ip" "controlplane_v4" {
  count   = lookup(var.controlplane, "count", 0)
  address = cidrhost(local.main_subnet, 11 + count.index)
  source {
    private_network_id = scaleway_vpc_private_network.main.id
  }
}

resource "scaleway_instance_server" "controlplane" {
  count              = lookup(var.controlplane, "count", 0)
  name               = "controlplane-${count.index + 1}"
  image              = data.scaleway_instance_image.talos[length(regexall("^COPARM1", lookup(try(var.controlplane, {}), "type", ""))) > 0 ? "arm64" : "amd64"].id
  type               = lookup(var.controlplane, "type", "DEV1-M")
  security_group_id  = scaleway_instance_security_group.controlplane.id
  placement_group_id = scaleway_instance_placement_group.controlplane.id
  tags               = concat(var.tags, ["infra", "controlplane"])

  routed_ip_enabled = true
  ip_ids            = [scaleway_instance_ip.controlplane_v4[count.index].id, scaleway_instance_ip.controlplane_v6[count.index].id]

  private_network {
    pn_id = scaleway_vpc_private_network.main.id
  }

  root_volume {
    size_in_gb = 20
  }

  lifecycle {
    ignore_changes = [
      boot_type,
      type,
      image,
      root_volume,
      user_data,
    ]
  }
}

resource "local_sensitive_file" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
  content = templatefile("${path.module}/templates/controlplane.yaml.tpl",
    merge(var.kubernetes, try(var.instances["all"], {}), {
      name = "controlplane-${count.index + 1}"
      # labels      = local.controlplane_labels
      nodeSubnets = [one(scaleway_vpc_private_network.main.ipv4_subnet).subnet, one(scaleway_vpc_private_network.main.ipv6_subnets).subnet]
      ipv4_local  = scaleway_ipam_ip.controlplane_v4[count.index].address
      ipv4_vip    = local.ipv4_vip

      access     = var.scaleway_access
      secret     = var.scaleway_secret
      project_id = var.scaleway_project_id
      region     = substr(var.regions[0], 0, 6)
      zone       = scaleway_vpc_private_network.main.region
      vpc_id     = split("/", scaleway_vpc_private_network.main.id)[1]
    })
  )
  filename        = "_cfgs/controlplane-${count.index + 1}.yaml"
  file_permission = "0600"
}

locals {
  controlplane_config = { for v in scaleway_instance_server.controlplane : v.name => "talosctl apply-config --insecure --nodes ${v.public_ip} --config-patch @_cfgs/${v.name}.yaml --file _cfgs/controlplane.yaml" }
}

output "controlplane_config" {
  value = local.controlplane_config
}
