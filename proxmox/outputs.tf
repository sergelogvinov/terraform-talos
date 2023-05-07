
output "controlplane_endpoint" {
  description = "Kubernetes controlplane endpoint"
  value       = local.ipv4_vip
}

output "controlplane_firstnode" {
  description = "Kubernetes controlplane first node"
  value       = try(flatten([for s in local.controlplanes : split("/", s.ipv4)[0]])[0], "127.0.0.1")
}

output "controlplane_apply" {
  description = "Kubernetes controlplane apply command"
  value = [for cp in local.controlplanes :
    "talosctl apply-config --insecure --nodes ${split("/", cp.ipv4)[0]} --config-patch @_cfgs/${cp.name}.yaml --file _cfgs/controlplane.yaml"
  ]
  depends_on = [proxmox_vm_qemu.controlplane]
}

output "controlplane_nodes" {
  description = "Kubernetes controlplane nodes"
  value = [
    for s in local.controlplanes :
    {
      name         = s.name
      ipv4_address = split("/", s.ipv4)[0]
      zone         = s.zone
    }
  ]
}
