
resource "proxmox_virtual_environment_role" "ccm" {
  role_id = "CCM"

  privileges = [
    "VM.Audit",
  ]
}

resource "proxmox_virtual_environment_role" "csi" {
  role_id = "CSI"

  privileges = [
    "VM.Audit",
    "VM.Config.Disk",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.Audit",
  ]
}
