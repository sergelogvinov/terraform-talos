
resource "local_file" "worker" {
  content = templatefile("${path.module}/modules/templates/worker-as.yaml.tpl",
    merge(var.kubernetes, {
      lbv4   = local.ipv4_vip
      labels = "project.io/node-pool=worker,hcloud/node-group=worker-as"
    })
  )
  filename        = "_cfgs/worker-as.yaml"
  file_permission = "0600"
}
