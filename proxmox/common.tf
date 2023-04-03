
resource "local_file" "worker_patch" {
  content = templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(var.kubernetes, {
      lbv4        = local.ipv4_vip
      nodeSubnets = var.vpc_main_cidr
    })
  )
  filename        = "${path.module}/templates/worker.patch.yaml"
  file_permission = "0600"
}
