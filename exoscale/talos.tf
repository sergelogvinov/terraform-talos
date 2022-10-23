
provider "talos" {}

resource "talos_machine_secrets" "talos" {}

resource "talos_machine_configuration_controlplane" "controlplane" {
  for_each         = { for idx, name in local.regions : name => idx }
  cluster_name     = var.kubernetes["clusterName"]
  cluster_endpoint = "https://${var.kubernetes["apiDomain"]}:6443"
  machine_secrets  = talos_machine_secrets.talos.machine_secrets
  docs_enabled     = false
  examples_enabled = false
  config_patches = [
    templatefile("${path.module}/templates/controlplane.yaml.tpl", merge(var.kubernetes, {
      nodeSubnets    = local.network[each.key].cidr
      ipv4_local_vip = cidrhost(local.network[each.key].cidr, 5)
      labels         = "topology.kubernetes.io/region=${each.key},topology.kubernetes.io/zone=${each.key}"
      key            = var.exoscale_api_key
      secret         = var.exoscale_api_secret
      zone           = each.key
    }))
  ]
}

resource "talos_machine_configuration_worker" "web" {
  for_each         = { for idx, name in local.regions : name => idx }
  cluster_name     = var.kubernetes["clusterName"]
  cluster_endpoint = "https://${var.kubernetes["apiDomain"]}:6443"
  machine_secrets  = talos_machine_secrets.talos.machine_secrets
  docs_enabled     = false
  examples_enabled = false
  config_patches = [
    templatefile("${path.module}/templates/worker.yaml.tpl", merge(var.kubernetes, {
      nodeSubnets    = local.network[each.key].cidr
      ipv4_local_vip = cidrhost(local.network[each.key].cidr, 5)
      labels         = "topology.kubernetes.io/region=${each.key},topology.kubernetes.io/zone=${each.key},project.io/node-pool=web"
    }))
  ]
}

locals {
  endpoints = try(flatten([for ip in flatten([for c in exoscale_instance_pool.controlplane : c.instances]) : ip.public_ip_address]), ["127.0.0.1"])
}

resource "talos_client_configuration" "talosconfig" {
  cluster_name    = var.kubernetes["clusterName"]
  machine_secrets = talos_machine_secrets.talos.machine_secrets
  endpoints       = length(local.endpoints) > 0 ? local.endpoints : ["127.0.0.1"]
}

resource "local_sensitive_file" "talosconfig" {
  content         = talos_client_configuration.talosconfig.talos_config
  filename        = "_cfgs/talosconfig"
  file_permission = "0600"
}

# resource "talos_cluster_kubeconfig" "kubeconfig" {
#   count        = length(local.endpoints) > 0 ? 1 : 0
#   talos_config = talos_client_configuration.talosconfig.talos_config
#   endpoint     = local.endpoints[0]
#   node         = local.endpoints[0]
# }

# resource "local_sensitive_file" "kubeconfig" {
#   count           = length(local.endpoints) > 0 ? 1 : 0
#   content         = talos_cluster_kubeconfig.kubeconfig[0].kube_config
#   filename        = "_cfgs/kubeconfig"
#   file_permission = "0600"
# }
