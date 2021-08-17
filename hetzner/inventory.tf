
# resource "local_file" "coredns_hosts" {
#   content = templatefile("${path.module}/templates/coredns_hosts.tpl",
#     {
#       masters = hcloud_server.controlplane
#       web     = flatten([for p in sort(keys(module.web)) : module.web[p].vms])
#     }
#   )
#   filename        = "_cfgs/coredns_hosts.yaml"
#   file_permission = "0640"
# }
