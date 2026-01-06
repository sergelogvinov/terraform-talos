
resource "proxmox_virtual_environment_role" "ccm" {
  role_id = "Kubernetes-CCM"

  privileges = [
    "Sys.Audit",
    "VM.Audit",
    # "VM.GuestAgent.Audit",
  ]
}

resource "proxmox_virtual_environment_role" "csi" {
  role_id = "Kubernetes-CSI"

  privileges = [
    "Sys.Audit",
    "VM.Audit",
    "VM.Config.Disk",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.Audit",
  ]
}

resource "proxmox_virtual_environment_role" "karpenter" {
  role_id = "Kubernetes-Karpenter"

  privileges = [
    "Sys.Audit", "Sys.AccessNetwork",
    "SDN.Audit", "SDN.Use",
    "Pool.Audit", "Pool.Allocate",
    "VM.Audit", "VM.Allocate", "VM.Clone",
    "VM.Config.CDROM", "VM.Config.CPU", "VM.Config.Memory", "VM.Config.Disk", "VM.Config.Network",
    "VM.Config.HWType", "VM.Config.Cloudinit", "VM.Config.Options", "VM.PowerMgmt",
    "Mapping.Audit", "Mapping.Use",
    "Datastore.Allocate", "Datastore.AllocateSpace", "Datastore.AllocateTemplate", "Datastore.Audit",
  ]
}
