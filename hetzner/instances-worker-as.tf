
resource "local_sensitive_file" "worker-as" {
  content = templatefile("${path.module}/templates/worker.yaml.tpl",
    merge(local.kubernetes, try(var.instances["all"], {}), {
      lbv4        = local.ipv4_vip
      nodeSubnets = var.vpc_main_cidr
      labels      = "${local.worker_labels},hcloud/node-group=worker-as"
    })
  )

  filename        = "_cfgs/worker-as.yaml"
  file_permission = "0600"
}
