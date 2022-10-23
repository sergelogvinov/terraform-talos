
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
      labels         = "topology.kubernetes.io/region=${each.key},topology.kubernetes.io/zone=${each.key},node.kubernetes.io/instance-type=${try(var.controlplane[each.key].type, "standard.tiny")}"
    }))
  ]
}

resource "talos_machine_configuration_worker" "worker" {
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
      labels         = "topology.kubernetes.io/region=${each.key},topology.kubernetes.io/zone=${each.key}"
    }))
  ]
}

resource "talos_client_configuration" "talosconfig" {
  for_each        = { for idx, name in local.regions : name => idx if try(var.controlplane[name].count, 0) > 0 }
  cluster_name    = var.kubernetes["clusterName"]
  machine_secrets = talos_machine_secrets.talos.machine_secrets
  endpoints       = [for k, v in exoscale_instance_pool.controlplane[each.key].instances : k.public_ip_address]
}

resource "local_sensitive_file" "talosconfig" {
  for_each        = { for idx, name in local.regions : name => idx if try(var.controlplane[name].count, 0) > 0 }
  content         = talos_client_configuration.talosconfig[each.key].talos_config
  filename        = "_cfgs/talosconfig-${each.key}"
  file_permission = "0600"
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  for_each     = { for idx, name in local.regions : name => idx if try(var.controlplane[name].count, 0) > 0 }
  talos_config = talos_client_configuration.talosconfig[each.key].talos_config
  endpoint     = [for k, v in exoscale_instance_pool.controlplane[each.key].instances : k.public_ip_address][0]
  node         = [for k, v in exoscale_instance_pool.controlplane[each.key].instances : k.public_ip_address][0]
}

resource "local_sensitive_file" "kubeconfig" {
  for_each        = { for idx, name in local.regions : name => idx if try(var.controlplane[name].count, 0) > 0 }
  content         = talos_cluster_kubeconfig.kubeconfig[each.key].kube_config
  filename        = "_cfgs/kubeconfig-${each.key}"
  file_permission = "0600"
}
