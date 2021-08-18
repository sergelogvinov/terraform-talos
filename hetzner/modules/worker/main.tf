
resource "hcloud_server" "worker" {
  count       = var.vm_items
  location    = var.location
  name        = "${var.vm_name}${count.index + 1}"
  image       = var.vm_image
  server_type = var.vm_type
  ssh_keys    = []
  keep_disk   = true
  labels      = var.labels

  user_data = templatefile("${path.module}/../templates/worker.yaml.tpl",
    merge(var.vm_params, {
      name = "${var.vm_name}${count.index + 1}"
      ipv4 = cidrhost(var.subnet, var.vm_ip_start + count.index)
    })
  )

  firewall_ids = var.vm_security_group
  network {
    network_id = var.network
    ip         = cidrhost(var.subnet, var.vm_ip_start + count.index)
  }

  lifecycle {
    ignore_changes = [
      image,
      server_type,
      user_data,
      ssh_keys,
    ]
  }

  # IPv6 hack
  # provisioner "local-exec" {
  #   command = "echo '${templatefile("${path.module}/../templates/worker-patch.json.tpl", { ipv6_address = self.ipv6_address })}' > _cfgs/${var.vm_name}${count.index + 1}.patch"
  # }
  # provisioner "local-exec" {
  #   command = "sleep 120 && talosctl --talosconfig _cfgs/talosconfig patch --nodes ${cidrhost(var.subnet, var.vm_ip_start + count.index)} machineconfig --patch-file _cfgs/${var.vm_name}${count.index + 1}.patch"
  # }
}

# resource "local_file" "worker" {
#   count = var.vm_items
#   content = templatefile("${path.module}/../templates/worker.yaml.tpl",
#     merge(var.vm_params, {
#       name = "${var.vm_name}${count.index + 1}"
#       ipv4 = cidrhost(var.subnet, var.vm_ip_start + count.index)
#     })
#   )
#   filename        = "${var.vm_name}${count.index + 1}.yaml"
#   file_permission = "0640"

#   depends_on = [hcloud_server.worker]
# }
