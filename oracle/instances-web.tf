
resource "oci_core_instance_pool" "web" {
  compartment_id            = var.compartment_ocid
  instance_configuration_id = oci_core_instance_configuration.web.id
  size                      = lookup(var.instances[local.zone], "web_count", 0)
  state                     = "RUNNING"
  display_name              = "${var.project}-web"

  placement_configurations {
    availability_domain = local.network_public[local.zone].availability_domain
    fault_domains       = data.oci_identity_fault_domains.domains.fault_domains.*.name
    primary_subnet_id   = local.network_public[local.zone].id
  }

  # load_balancers {
  #   backend_set_name = oci_network_load_balancer_backend_set.web.name
  #   load_balancer_id = oci_network_load_balancer_network_load_balancer.web.id
  #   port             = 80
  #   vnic_selection   = "PrimaryVnic"
  # }

  lifecycle {
    ignore_changes = [
      # size,
      state,
      defined_tags
    ]
  }
}

resource "oci_core_instance_configuration" "web" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.project}-web"

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id                      = var.compartment_ocid
      display_name                        = "${var.project}-web"
      is_pv_encryption_in_transit_enabled = true
      preferred_maintenance_action        = "LIVE_MIGRATE"
      launch_mode                         = "NATIVE"

      shape = lookup(var.instances[local.zone], "web_instance_shape", "VM.Standard.E2.1.Micro")
      shape_config {
        ocpus         = lookup(var.instances[local.zone], "web_instance_ocpus", 1)
        memory_in_gbs = lookup(var.instances[local.zone], "web_instance_memgb", 1)
      }

      metadata = {
        user_data = templatefile("${path.module}/templates/web.yaml.tpl",
          merge(var.kubernetes, {
            lbv4        = local.lbv4_local
            lbv4_web    = local.lbv4_web
            nodeSubnets = local.network_public[local.zone].cidr_block
          })
        )
      }

      source_details {
        source_type             = "image"
        image_id                = data.oci_core_images.talos_x64.images[0].id
        boot_volume_size_in_gbs = "50"
      }
      create_vnic_details {
        display_name              = "${var.project}-web"
        assign_private_dns_record = false
        assign_public_ip          = true
        nsg_ids                   = [local.nsg_talos, local.nsg_cilium, local.nsg_web, local.nsg_contolplane]
        subnet_id                 = local.network_public[local.zone].id
        skip_source_dest_check    = true
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

data "oci_core_instance_pool_instances" "web" {
  compartment_id   = var.compartment_ocid
  instance_pool_id = oci_core_instance_pool.web.id
}

resource "oci_network_load_balancer_backend" "web_http" {
  for_each = { for instances in data.oci_core_instance_pool_instances.web.instances.* : instances.display_name => instances.id }

  backend_set_name         = oci_network_load_balancer_backend_set.web_http[0].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web[0].id
  port                     = 80

  name      = "web-http-lb"
  target_id = each.value

  depends_on = [
    oci_core_instance_pool.web
  ]
}

resource "oci_network_load_balancer_backend" "web_https" {
  for_each = { for instances in data.oci_core_instance_pool_instances.web.instances.* : instances.display_name => instances.id }

  backend_set_name         = oci_network_load_balancer_backend_set.web_https[0].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web[0].id
  port                     = 443

  name      = "web-https-lb"
  target_id = each.value

  depends_on = [
    oci_core_instance_pool.web
  ]
}
