
data "openstack_identity_auth_scope_v3" "os" {
  name = var.openstack_project
}

data "openstack_images_image_v2" "debian" {
  count       = length(var.regions)
  region      = element(var.regions, count.index)
  name        = "Debian 10"
  most_recent = true
  visibility  = "public"
}

resource "openstack_compute_keypair_v2" "keypair" {
  count      = length(var.regions)
  region     = element(var.regions, count.index)
  name       = "Terraform"
  public_key = file("~/.ssh/terraform.pub")
}

resource "openstack_images_image_v2" "talos" {
  count            = length(var.regions)
  region           = element(var.regions, count.index)
  name             = "talos"
  container_format = "bare"
  disk_format      = "raw"
  min_disk_gb      = 5

  properties = {
    # hw_firmware_type = "uefi"
    hw_disk_bus   = "scsi"
    hw_scsi_model = "virtio-scsi"
    support_rtm   = "yes"
  }

  visibility = "private"
  # image_source_url = "https://"
  local_file_path = "../../talos/disk.raw"
}
