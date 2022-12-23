
resource "oci_core_instance_pool" "worker" {
  for_each                  = { for idx, ad in local.zones : ad => idx + 1 }
  compartment_id            = var.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.worker[each.key].id
  size                      = lookup(var.instances[each.key], "worker_count", 0)
  state                     = "RUNNING"
  display_name              = "${var.project}-worker-${each.value}"
  defined_tags              = merge(var.tags, { "Kubernetes.Role" = "web" })

  placement_configurations {
    availability_domain = local.network_private[each.key].availability_domain
    fault_domains       = data.oci_identity_fault_domains.domains[each.key].fault_domains.*.name
    primary_subnet_id   = local.network_private[each.key].id
  }

  lifecycle {
    ignore_changes = [
      state,
      defined_tags
    ]
  }
}

locals {
  worker_labels = "project.io/node-pool=worker"
}

resource "oci_core_instance_configuration" "worker" {
  for_each       = { for idx, ad in local.zones : ad => idx + 1 }
  compartment_id = var.compartment_ocid
  display_name   = "${var.project}-worker-${each.value}"
  defined_tags   = merge(var.tags, { "Kubernetes.Role" = "web" })

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id                      = var.compartment_ocid
      display_name                        = "${var.project}-worker"
      is_pv_encryption_in_transit_enabled = true
      preferred_maintenance_action        = "LIVE_MIGRATE"
      launch_mode                         = "PARAVIRTUALIZED"

      shape = lookup(var.instances[each.key], "worker_instance_shape", "VM.Standard.E2.1.Micro")
      shape_config {
        ocpus         = lookup(var.instances[each.key], "worker_instance_ocpus", 1)
        memory_in_gbs = lookup(var.instances[each.key], "worker_instance_memgb", 1)
      }

      metadata = {
        user_data = base64encode(templatefile("${path.module}/templates/worker.yaml.tpl",
          merge(var.kubernetes, {
            lbv4        = local.lbv4_local
            clusterDns  = cidrhost(split(",", var.kubernetes["serviceSubnets"])[0], 10)
            nodeSubnets = local.network_public[each.key].cidr_block
            labels      = local.worker_labels
          })
        ))
      }

      source_details {
        source_type             = "image"
        image_id                = data.oci_core_images.talos_x64.images[0].id
        boot_volume_size_in_gbs = "50"
      }
      create_vnic_details {
        display_name              = "${var.project}-worker"
        assign_private_dns_record = false # always off!!! hostname issue
        assign_public_ip          = false
        nsg_ids                   = [local.nsg_talos, local.nsg_cilium, local.nsg_worker]
        subnet_id                 = local.network_public[each.key].id
        skip_source_dest_check    = true
      }

      agent_config {
        are_all_plugins_disabled = true
        is_management_disabled   = true
        is_monitoring_disabled   = true
      }
      launch_options {
        network_type = "PARAVIRTUALIZED" # "VFIO"
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
    ignore_changes = [
      defined_tags
    ]
  }
}
