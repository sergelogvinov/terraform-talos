
resource "exoscale_anti_affinity_group" "controlplane" {
  name        = "${local.project}-controlplane"
  description = "controlplane"
}

resource "exoscale_instance_pool" "controlplane" {
  for_each        = { for idx, name in local.regions : name => idx if try(var.controlplane[name].count, 0) > 0 }
  zone            = each.key
  name            = "controlplane-${each.key}"
  instance_prefix = "controlplane-${each.key}"
  size            = var.controlplane[each.key].count
  template_id     = data.exoscale_compute_template.debian[each.key].id
  user_data       = base64encode(talos_machine_configuration_controlplane.controlplane[each.key].machine_config)

  ipv6               = true
  security_group_ids = [local.network_secgroup[each.key].controlplane, local.network_secgroup[each.key].common]
  network_ids        = [local.network[each.key].id]
  affinity_group_ids = [exoscale_anti_affinity_group.controlplane.id]

  key_pair      = exoscale_ssh_key.terraform.name
  instance_type = try(var.controlplane[each.key].type, "standard.tiny")
  disk_size     = 10

  labels = merge(var.tags, { type = "infra" })

  lifecycle {
    ignore_changes = [user_data, labels]
  }
}

resource "local_sensitive_file" "controlplane" {
  for_each        = { for idx, name in local.regions : name => idx }
  content         = talos_machine_configuration_controlplane.controlplane[each.key].machine_config
  filename        = "_cfgs/controlplane-${each.key}.yaml"
  file_permission = "0600"
}
