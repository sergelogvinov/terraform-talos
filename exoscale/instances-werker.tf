
resource "exoscale_instance_pool" "worker" {
  for_each        = { for idx, name in local.regions : name => idx if try(var.instances[name].worker_count, 0) > 0 }
  zone            = each.key
  name            = "worker-${each.key}"
  instance_prefix = "worker"
  size            = var.instances[each.key].worker_count
  template_id     = data.exoscale_compute_template.debian[each.key].id
  user_data       = base64encode(talos_machine_configuration_worker.web[each.key].machine_config)

  ipv6               = true
  security_group_ids = [local.network_secgroup[each.key].common]
  network_ids        = [local.network[each.key].id]

  key_pair      = exoscale_ssh_key.terraform.name
  instance_type = try(var.instances[each.key].worker_type, "standard.tiny")
  disk_size     = 16

  labels = merge(var.tags, { type = "worker" })

  lifecycle {
    ignore_changes = [user_data, labels]
  }
}

# resource "local_sensitive_file" "worker" {
#   for_each        = { for idx, name in local.regions : name => idx }
#   content         = talos_machine_configuration_worker.web[each.key].machine_config
#   filename        = "_cfgs/worker-${each.key}.yaml"
#   file_permission = "0600"
# }
