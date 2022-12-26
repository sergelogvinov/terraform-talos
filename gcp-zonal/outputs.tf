
output "controlplane_endpoint" {
  value = try(flatten([for c in module.controlplane : c.controlplane_endpoints])[0], "")
}
