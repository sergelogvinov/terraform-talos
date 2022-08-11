
# resource "local_file" "worker" {
#   content = templatefile("${path.module}/templates/worker.yaml",
#     merge(var.kubernetes, {
#       ipv4_vip = local.ipv4_vip
#       labels   = "project.io/node-pool=worker,hcloud/node-group=worker-as"
#     })
#   )
#   filename        = "_cfgs/worker-as.yaml"
#   file_permission = "0600"
# }
