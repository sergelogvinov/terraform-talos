
# data "oci_core_vnic_attachments" "contolplane" {
#   compartment_id = var.compartment_ocid
#   instance_id    = oci_core_instance.contolplane.id
# }

# resource "oci_core_ipv6" "contolplane" {
#   vnic_id = data.oci_core_vnic_attachments.contolplane.vnic_attachments[0]["vnic_id"]
# }

# resource "oci_core_instance" "contolplane" {
#   compartment_id      = var.compartment_ocid
#   display_name        = "contolplane-1"
#   availability_domain = local.network_public["jNdv:eu-amsterdam-1-AD-1"].availability_domain
#   shape               = "VM.Standard.E2.1.Micro"

#   metadata = {
#     ssh_authorized_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd+wfWIKi1dDZuCsd/zNw2n4WuHHa21N/Ltmo3umH2d local"
#     user_data           = base64encode("# noop")
#   }

#   source_details {
#     source_type             = "image"
#     source_id               = data.oci_core_images.talos_x64.images[0].id
#     boot_volume_size_in_gbs = "50"
#   }
#   create_vnic_details {
#     assign_public_ip = true
#     subnet_id        = local.network_public["jNdv:eu-amsterdam-1-AD-1"].id
#     private_ip       = cidrhost(local.network_public["jNdv:eu-amsterdam-1-AD-1"].cidr_block, 11)
#     nsg_ids          = [local.nsg_talos, local.nsg_cilium]
#   }

#   launch_options {
#     firmware                            = "UEFI_64"
#     is_pv_encryption_in_transit_enabled = true
#     remote_data_volume_type             = "PARAVIRTUALIZED"
#     network_type                        = "PARAVIRTUALIZED"
#   }
#   instance_options {
#     are_legacy_imds_endpoints_disabled = true
#   }
#   availability_config {
#     is_live_migration_preferred = true
#     recovery_action             = "RESTORE_INSTANCE"
#   }

#   timeouts {
#     create = "10m"
#   }

#   lifecycle {
#     ignore_changes = [
#       defined_tags,
#       create_vnic_details["defined_tags"],
#       launch_options["is_pv_encryption_in_transit_enabled"]
#     ]
#   }
# }

# resource "oci_network_load_balancer_backend" "contolplane" {
#   backend_set_name         = oci_network_load_balancer_backend_set.contolplane.name
#   network_load_balancer_id = oci_network_load_balancer_network_load_balancer.contolplane.id
#   port                     = 80

#   name      = "contolplane-1"
#   target_id = oci_core_instance.contolplane.id
# }
