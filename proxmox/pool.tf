
resource "proxmox_virtual_environment_pool" "pool" {
  comment = "Kubernetes cluster ${local.kubernetes["clusterName"]}"
  pool_id = local.kubernetes["clusterName"]
}
