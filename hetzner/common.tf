
data "hcloud_image" "talos" {
  with_selector = "type=infra"
}

data "hcloud_ssh_key" "infra" {
  with_selector = "type=infra"
}

# resource "talos_cluster_config" "talos_config" {
#   cluster_name = var.cluster_name
#   endpoint     = "https://${hcloud_load_balancer.api.ip}:6443"
# }
