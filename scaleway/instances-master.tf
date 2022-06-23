
resource "scaleway_instance_ip" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
}

locals {
  controlplane_labels = "topology.kubernetes.io/region=fr-par,topology.kubernetes.io/zone=${var.regions[0]}"
}

resource "scaleway_instance_server" "controlplane" {
  count              = lookup(var.controlplane, "count", 0)
  name               = "master-${count.index + 1}"
  image              = data.scaleway_instance_image.talos.id
  type               = lookup(var.controlplane, "type", "DEV1-M")
  enable_ipv6        = true
  ip_id              = scaleway_instance_ip.controlplane[count.index].id
  security_group_id  = scaleway_instance_security_group.controlplane.id
  placement_group_id = scaleway_instance_placement_group.controlplane.id
  tags               = concat(var.tags, ["infra", "master"])

  private_network {
    pn_id = scaleway_vpc_private_network.main.id
  }

  user_data = {
    cloud-init = templatefile("${path.module}/templates/controlplane.yaml",
      merge(var.kubernetes, {
        name       = "master-${count.index + 1}"
        ipv4_vip   = local.ipv4_vip
        ipv4_local = cidrhost(local.main_subnet, 11 + count.index)
        lbv4       = local.lbv4
        ipv4       = scaleway_instance_ip.controlplane[count.index].address
        labels     = "${local.controlplane_labels},node.kubernetes.io/instance-type=${lookup(var.controlplane, "type", "DEV1-M")}"
        access     = var.scaleway_access
        secret     = var.scaleway_secret
        region     = "fr-par"
        project_id = var.scaleway_project_id
      })
    )
  }

  lifecycle {
    ignore_changes = [
      image,
      type,
      user_data,
    ]
  }
}

resource "scaleway_vpc_public_gateway_dhcp_reservation" "controlplane" {
  count              = lookup(var.controlplane, "count", 0)
  gateway_network_id = scaleway_vpc_gateway_network.main.id
  mac_address        = scaleway_instance_server.controlplane[count.index].private_network.0.mac_address
  ip_address         = cidrhost(local.main_subnet, 11 + count.index)
}

resource "scaleway_instance_placement_group" "controlplane" {
  name        = "controlplane"
  policy_type = "max_availability"
  policy_mode = "enforced"
}
