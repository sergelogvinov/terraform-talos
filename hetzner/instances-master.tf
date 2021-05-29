
resource "hcloud_server" "controlplane" {
  count       = lookup(var.controlplane, "count", 0)
  location    = element(var.regions, count.index)
  name        = "kube-api-${count.index + 1}"
  image       = data.hcloud_image.talos.id
  server_type = lookup(var.controlplane, "type", "cpx11")
  keep_disk   = true
  labels      = merge(var.tags, { type = "infra", label = "master" })

  firewall_ids = [hcloud_firewall.controlplane.id]
  network {
    network_id = hcloud_network.main.id
    ip         = cidrhost(hcloud_network_subnet.core.ip_range, 11 + count.index)
  }

  lifecycle {
    ignore_changes = [
      user_data,
      ssh_keys,
    ]
  }
}

resource "hcloud_load_balancer_target" "api" {
  count            = lookup(var.controlplane, "count", 0)
  type             = "server"
  load_balancer_id = hcloud_load_balancer.api.id
  server_id        = hcloud_server.controlplane[count.index].id
}

resource "local_file" "init" {
  count = lookup(var.controlplane, "count", 0)
  content = templatefile("${path.module}/templates/api.yaml.tpl",
    merge(var.vm_params, {
      name       = "kube-api-${count.index + 1}"
      ipv4       = hcloud_server.controlplane[count.index].ipv4_address
      ipv6       = hcloud_server.controlplane[count.index].ipv6_address
      lbv4_local = cidrhost(hcloud_network_subnet.core.ip_range, 5)
      lbv4       = hcloud_load_balancer.api.ipv4
      lbv6       = hcloud_load_balancer.api.ipv6
    })
  )
  filename        = "controlplane-${count.index + 1}.yaml"
  file_permission = "0640"

  depends_on = [hcloud_server.controlplane]
}
