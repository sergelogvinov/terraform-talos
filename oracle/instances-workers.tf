
resource "oci_core_instance_pool" "workers" {
  compartment_id            = var.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.workers.id
  size                      = lookup(var.instances[local.zone], "worker_count", 0)
  state                     = "RUNNING"
  display_name              = "${var.project}-workers"

  placement_configurations {
    availability_domain = local.network_private[local.zone].availability_domain
    fault_domains       = data.oci_identity_fault_domains.domains.fault_domains.*.name
    primary_subnet_id   = local.network_private[local.zone].id
  }

  lifecycle {
    ignore_changes = [
      state,
      defined_tags
    ]
  }
}

resource "oci_core_instance_configuration" "workers" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.project}-workers"

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id                      = var.compartment_ocid
      display_name                        = "${var.project}-workers"
      is_pv_encryption_in_transit_enabled = true
      preferred_maintenance_action        = "LIVE_MIGRATE"
      launch_mode                         = "NATIVE"

      shape = lookup(var.instances[local.zone], "worker_instance_shape", "VM.Standard.E2.1.Micro")
      shape_config {
        ocpus         = lookup(var.instances[local.zone], "worker_instance_ocpus", 1)
        memory_in_gbs = lookup(var.instances[local.zone], "worker_instance_memgb", 1)
      }

      metadata = {
        user_data = base64encode(templatefile("${path.module}/templates/worker.yaml.tpl",
          merge(var.kubernetes, {
            lbv4        = local.lbv4_local
            nodeSubnets = local.network_private[local.zone].cidr_block
          })
        ))
      }

      source_details {
        source_type             = "image"
        image_id                = data.oci_core_images.talos_x64.images[0].id
        boot_volume_size_in_gbs = "50"
      }
      create_vnic_details {
        display_name              = "${var.project}-workers"
        assign_private_dns_record = false
        assign_public_ip          = false
        nsg_ids                   = [local.nsg_talos, local.nsg_cilium, local.nsg_worker]
        subnet_id                 = local.network_private[local.zone].id
      }

      agent_config {
        is_management_disabled = false
        is_monitoring_disabled = false
      }
      launch_options {
        network_type = "PARAVIRTUALIZED"
      }
      instance_options {
        are_legacy_imds_endpoints_disabled = true
      }
      availability_config {
        recovery_action = "RESTORE_INSTANCE"
      }
    }
  }

  lifecycle {
    create_before_destroy = "true"
  }
}
