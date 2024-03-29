
resource "exoscale_anti_affinity_group" "web" {
  name        = "${local.project}-web"
  description = "web"
}

resource "exoscale_instance_pool" "web" {
  for_each        = { for idx, name in local.regions : name => idx if try(var.instances[name].web_count, 0) > 0 }
  zone            = each.key
  name            = "web-${each.key}"
  instance_prefix = "web"
  size            = var.instances[each.key].web_count
  template_id     = data.exoscale_compute_template.debian[each.key].id
  user_data       = base64encode(talos_machine_configuration_worker.web[each.key].machine_config)

  ipv6               = true
  security_group_ids = [local.network_secgroup[each.key].web, local.network_secgroup[each.key].common]
  network_ids        = [local.network[each.key].id]
  affinity_group_ids = [exoscale_anti_affinity_group.web.id]

  key_pair      = exoscale_ssh_key.terraform.name
  instance_type = try(var.instances[each.key].web_type, "standard.tiny")
  disk_size     = 16

  labels = merge(var.tags, { type = "web" })

  lifecycle {
    ignore_changes = [size, user_data, labels]
  }
}
