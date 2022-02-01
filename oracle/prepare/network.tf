
resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  display_name   = var.project
  cidr_blocks    = [var.vpc_main_cidr]
  is_ipv6enabled = true
  defined_tags   = var.tags
  dns_label      = var.project

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = oci_core_vcn.main.display_name
  defined_tags   = var.tags
  enabled        = true

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_service_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = oci_core_vcn.main.display_name
  defined_tags   = var.tags

  services {
    service_id = data.oci_core_services.object_store.services[0]["id"]
  }

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = oci_core_vcn.main.display_name
  defined_tags   = var.tags

  route_rules {
    network_entity_id = oci_core_internet_gateway.main.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
  route_rules {
    network_entity_id = oci_core_internet_gateway.main.id
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
  }

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_subnet" "regional_lb" {
  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_block, 10, 0)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, 0)
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.main.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false

  display_name = "${oci_core_vcn.main.display_name}-regional-lb"
  defined_tags = merge(var.tags, { "Kubernetes.Type" = "infra" })
  dns_label    = "lb"

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_subnet" "regional" {
  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_block, 10, 1)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, 1)
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.main.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false

  display_name = "${oci_core_vcn.main.display_name}-regional"
  defined_tags = var.tags
  dns_label    = "regional"

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_subnet" "public" {
  for_each = { for idx, ad in local.zones : ad => idx }

  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_block, 8, each.value + 1)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, each.value + 10)
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.main.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  availability_domain        = each.key

  display_name = "${oci_core_vcn.main.display_name}-public-zone-${each.value}"
  defined_tags = var.tags
  dns_label    = "public${each.value}"

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_subnet" "private" {
  for_each = { for idx, ad in local.zones : ad => idx }

  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_block, 8, each.value + 8)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, each.value + 16)
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.private.id
  prohibit_public_ip_on_vnic = true
  availability_domain        = each.key

  display_name = "${oci_core_vcn.main.display_name}-private-zone-${each.value}"
  defined_tags = var.tags
  dns_label    = "private${each.value}"

  lifecycle {
    ignore_changes = [
      defined_tags
    ]
  }
}
