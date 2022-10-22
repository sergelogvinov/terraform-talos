
resource "exoscale_compute_instance" "gw" {
  for_each    = { for idx, name in var.regions : name => idx if try(var.capabilities[name].network_gw_enable, false) }
  zone        = each.key
  name        = "${var.project}-${each.key}-gw"
  template_id = data.exoscale_compute_template.debian[each.key].id

  ipv6               = true
  security_group_ids = [exoscale_security_group.gw.id, exoscale_security_group.common.id]
  network_interface {
    network_id = exoscale_private_network.main[each.key].id
    ip_address = cidrhost("${exoscale_private_network.main[each.key].start_ip}/24", -3)
  }

  type      = try(var.capabilities[each.key].network_gw_type, "standard.micro")
  disk_size = 10
}
