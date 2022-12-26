
output "controlplane" {
  value = google_compute_instance_from_template.controlplane
}

output "controlplane_endpoints" {
  value = lookup(var.controlplane, "count", 0) > 0 ? google_compute_instance_from_template.controlplane[0].network_interface[0].access_config[0].nat_ip : ""
}

output "instance_group_id" {
  value = google_compute_instance_group.controlplane.id
}
