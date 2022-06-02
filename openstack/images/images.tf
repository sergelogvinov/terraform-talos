
resource "openstack_images_image_v2" "talos" {
  for_each         = { for idx, name in var.regions : name => idx }
  region           = each.key
  name             = "talos"
  container_format = "bare"
  disk_format      = "raw"
  min_disk_gb      = 5
  min_ram_mb       = 1
  tags             = ["talos-1.1.0-beta.0"]

  properties = {
    hw_firmware_type = "uefi"
    hw_disk_bus      = "scsi"
    hw_scsi_model    = "virtio-scsi"
    support_rtm      = "yes"
  }

  visibility      = "private"
  local_file_path = "disk.raw"
}
