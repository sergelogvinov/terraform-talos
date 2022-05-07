
resource "openstack_images_image_v2" "talos" {
  count            = length(var.regions)
  region           = element(var.regions, count.index)
  name             = "talos"
  container_format = "bare"
  disk_format      = "raw"
  min_disk_gb      = 5
  min_ram_mb       = 1
  tags             = ["talos-1.0.4"]

  properties = {
    hw_firmware_type = "uefi"
    hw_disk_bus      = "scsi"
    hw_scsi_model    = "virtio-scsi"
    support_rtm      = "yes"
  }

  visibility      = "private"
  local_file_path = "disk.raw"
}
