
locals {
  worker_prefix = "worker"
  worker_labels = "node-pool=worker"
}

resource "scaleway_instance_ip" "worker_v6" {
  count = lookup(try(var.instances[var.regions[0]], {}), "worker_count", 0)
  type  = "routed_ipv6"
}

resource "scaleway_instance_server" "worker" {
  count             = lookup(try(var.instances[var.regions[0]], {}), "worker_count", 0)
  name              = "${local.worker_prefix}-${count.index + 1}"
  image             = data.scaleway_instance_image.talos[length(regexall("^COPARM1", lookup(try(var.instances[var.regions[0]], {}), "worker_type", 0))) > 0 ? "arm64" : "amd64"].id
  type              = lookup(var.instances[var.regions[0]], "worker_type", "DEV1-M")
  security_group_id = scaleway_instance_security_group.worker.id
  tags              = concat(var.tags, ["worker"])

  routed_ip_enabled = true
  ip_ids            = [scaleway_instance_ip.worker_v6[count.index].id]

  private_network {
    pn_id = scaleway_vpc_private_network.main.id
  }

  root_volume {
    size_in_gb = 20
  }

  user_data = {
    cloud-init = templatefile("${path.module}/templates/worker.yaml.tpl",
      merge(local.kubernetes, try(var.instances["all"], {}), {
        ipv4_vip    = local.ipv4_vip
        nodeSubnets = [one(scaleway_vpc_private_network.main.ipv4_subnet).subnet, one(scaleway_vpc_private_network.main.ipv6_subnets).subnet]
        labels      = local.worker_labels
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
