
resource "local_sensitive_file" "worker-as" {
  content = templatefile("${path.module}/templates/worker-as.yaml.tpl",
    merge(var.kubernetes, {
      lbv4        = local.ipv4_vip
      nodeSubnets = var.vpc_main_cidr
      labels      = "project.io/node-pool=worker,hcloud/node-group=worker-as"
    })
  )

  filename        = "_cfgs/worker-as.yaml"
  file_permission = "0600"
}
