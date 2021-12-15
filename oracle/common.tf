
data "oci_core_images" "talos_x64" {
  compartment_id   = var.compartment_ocid
  operating_system = "Canonical Ubuntu"
  # operating_system_version = "20.04"
  state   = "AVAILABLE"
  sort_by = "TIMECREATED"

  # filter {
  #   name   = "launch_mode"
  #   values = ["NATIVE"]
  #   regex  = true
  # }
  # filter {
  #   name   = "display_name"
  #   values = ["Linux"]
  #   regex  = true
  # }
  # filter {
  #   name   = "network_type"
  #   values = ["VFIO"]
  # }
}

data "oci_core_image_shapes" "talos_x64" {
  image_id = data.oci_core_images.talos_x64.images[0].id
}

data "oci_identity_fault_domains" "fault_domains" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.network_public["jNdv:eu-amsterdam-1-AD-1"].availability_domain
}
