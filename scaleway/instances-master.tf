
resource "scaleway_instance_ip" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
  # zone    = element(var.regions, count.index)
}

resource "scaleway_instance_server" "controlplane" {
  count = lookup(var.controlplane, "count", 0)
  # zone    = element(var.regions, count.index)
  name              = "master-${count.index + 1}"
  image             = data.scaleway_instance_image.talos.id
  type              = lookup(var.controlplane, "type", "DEV1-M")
  enable_ipv6       = true
  ip_id             = scaleway_instance_ip.controlplane[count.index].id
  security_group_id = scaleway_instance_security_group.controlplane.id
  tags              = concat(var.tags, ["infra", "master"])

  user_data = {
    cloud-init = templatefile("${path.module}/templates/controlplane.yaml",
      merge(var.kubernetes, {
        name = "master-${count.index + 1}"
        type = count.index == 0 ? "init" : "controlplane"
        lbv4 = local.lbv4
        ipv4 = scaleway_instance_ip.controlplane[count.index].address
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

resource "scaleway_instance_private_nic" "controlplane" {
  count              = lookup(var.controlplane, "count", 0)
  server_id          = scaleway_instance_server.controlplane[count.index].id
  private_network_id = scaleway_vpc_private_network.main.id
}
