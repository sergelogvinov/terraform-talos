
# resource "oci_core_instance_pool" "workers" {
#   compartment_id            = var.compartment_ocid
#   instance_configuration_id = oci_core_instance_configuration.workers.id
#   size                      = 0
#   state                     = "RUNNING"
#   display_name              = "${var.project}-workers"

#   placement_configurations {
#     availability_domain = local.network_public["jNdv:eu-amsterdam-1-AD-1"].availability_domain
#     fault_domains       = data.oci_identity_fault_domains.fault_domains.fault_domains.*.name
#     primary_subnet_id   = local.network_public["jNdv:eu-amsterdam-1-AD-1"].id
#   }

#   lifecycle {
#     ignore_changes = [
#       size,
#       state,
#       defined_tags
#     ]
#   }
# }

# resource "oci_core_instance_configuration" "workers" {
#   compartment_id = var.compartment_ocid
#   display_name   = "${var.project}-workers"

#   instance_details {
#     instance_type = "compute"

#     launch_details {
#       compartment_id                      = var.compartment_ocid
#       shape                               = "VM.Standard.E2.1.Micro"
#       display_name                        = "${var.project}-workers"
#       is_pv_encryption_in_transit_enabled = true
#       preferred_maintenance_action        = "LIVE_MIGRATE"
#       launch_mode                         = "NATIVE"

#       metadata = {
#         ssh_authorized_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDd+wfWIKi1dDZuCsd/zNw2n4WuHHa21N/Ltmo3umH2d local"
#       }

#       source_details {
#         source_type             = "image"
#         image_id                = data.oci_core_images.talos_x64.images[0].id
#         boot_volume_size_in_gbs = "50"
#       }
#       create_vnic_details {
#         display_name              = "${var.project}-workers"
#         assign_private_dns_record = false
#         assign_public_ip          = true
#         nsg_ids                   = [local.nsg_talos, local.nsg_web]
#         subnet_id                 = local.network_public["jNdv:eu-amsterdam-1-AD-1"].id
#       }

#       agent_config {
#         is_management_disabled = false
#         is_monitoring_disabled = false
#       }
#       launch_options {
#         network_type = "PARAVIRTUALIZED"
#       }
#       instance_options {
#         are_legacy_imds_endpoints_disabled = true
#       }
#       availability_config {
#         recovery_action = "RESTORE_INSTANCE"
#       }
#     }
#   }

#   lifecycle {
#     create_before_destroy = "true"
#   }
# }
