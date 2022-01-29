
# FIXME: does not work without enable_dynamic_ip

resource "scaleway_instance_server" "web" {
  count             = lookup(var.instances, "web_count", 0)
  name              = "web-${count.index + 1}"
  image             = data.scaleway_instance_image.talos.id
  type              = lookup(var.instances, "web_instance_type", "DEV1-M")
  enable_ipv6       = true
  enable_dynamic_ip = true
  security_group_id = scaleway_instance_security_group.web.id
  tags              = concat(var.tags, ["web"])

  private_network {
    pn_id = scaleway_vpc_private_network.main.id
  }

  user_data = {
    cloud-init = templatefile("${path.module}/templates/web.yaml.tpl",
      merge(var.kubernetes, {
        name        = "web-${count.index + 1}"
        type        = "worker"
        ipv4_vip    = local.ipv4_vip
        clusterDns  = cidrhost(split(",", var.kubernetes["serviceSubnets"])[0], 10)
        nodeSubnets = local.main_subnet
        labels      = "topology.kubernetes.io/region=fr-par"
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
