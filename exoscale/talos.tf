
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
      ipv4_local_vip = cidrhost(local.network[each.key].cidr, 5)
      labels         = "topology.kubernetes.io/region=${each.key},topology.kubernetes.io/zone=${each.key}"
    }))
  ]
}
