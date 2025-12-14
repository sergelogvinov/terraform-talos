
resource "proxmox_virtual_environment_role" "ccm" {
  role_id = "Kubernetes-CCM"

  privileges = [
    "Sys.Audit",
    "VM.Audit",
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
