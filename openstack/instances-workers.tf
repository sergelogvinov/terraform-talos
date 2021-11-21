
resource "openstack_networking_port_v2" "worker" {
  count          = length(var.regions)
  region         = element(var.regions, count.index)
  name           = "worker-${count.index + 1}"
  network_id     = data.openstack_networking_network_v2.main[count.index].id
  admin_state_up = "true"

  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.private[count.index].id
    ip_address = cidrhost(openstack_networking_subnet_v2.private[count.index].cidr, 40 + count.index)
  }
}

locals {
  worker_labels = "project.io/node-pool=worker"
}

resource "openstack_compute_instance_v2" "worker" {
  count       = 0
  name        = "worker-${count.index + 1}"
  image_id    = openstack_images_image_v2.talos[count.index].id
  flavor_name = "s1-2"
  region      = element(var.regions, count.index)

  user_data = templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, {
      name        = "worker-${count.index + 1}"
      lbv4        = local.lbv4
      nodeSubnets = var.vpc_main_cidr
      labels      = local.worker_labels
    })
  )

  network {
    port = openstack_networking_port_v2.worker[count.index].id
  }

  lifecycle {
    ignore_changes = [user_data, image_id]
  }
}

# resource "local_file" "worker" {
#   count = 1
#   content = templatefile("${path.module}/templates/worker.yaml.tpl",
#     merge(var.kubernetes, {
#       name        = "worker-${count.index + 1}"
#       lbv4        = local.lbv4
#       nodeSubnets = var.vpc_main_cidr
#       labels      = local.worker_labels
#     })
#   )
#   filename        = "_cfgs/worker-${count.index + 1}.yaml"
#   file_permission = "0640"
# }
