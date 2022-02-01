
data "oci_core_images" "talos_x64" {
  compartment_id   = var.compartment_ocid
  operating_system = "Talos"
  state            = "AVAILABLE"
  sort_by          = "TIMECREATED"

  filter {
    name   = "display_name"
    values = ["amd64"]
    regex  = true
  }
}

data "oci_core_images" "talos_arm" {
  compartment_id   = var.compartment_ocid
  operating_system = "Talos"
  state            = "AVAILABLE"
  sort_by          = "TIMECREATED"

  filter {
    name   = "display_name"
    values = ["arm64"]
    regex  = true
  }
}

# data "oci_core_image_shapes" "talos_x64" {
#   image_id = data.oci_core_images.talos_x64.images[0].id
# }

data "oci_identity_fault_domains" "domains" {
  for_each            = { for idx, ad in local.zones : ad => idx }
  compartment_id      = var.compartment_ocid
  availability_domain = local.network_public[each.key].availability_domain
}
