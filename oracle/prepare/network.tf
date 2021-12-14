
resource "oci_core_vcn" "main" {
  compartment_id = var.tenancy_ocid

  display_name   = "main"
  cidr_blocks    = [var.vpc_main_cidr]
  is_ipv6enabled = true
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "main"
  enabled        = true
}

resource "oci_core_service_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  route_table_id = oci_core_route_table.transit.id
  display_name   = "main"

  services {
    service_id = data.oci_core_services.main.services[0]["id"]
  }
}

resource "oci_core_route_table" "transit" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "Default Transit Route Table"
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "main"

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
  route_rules {
    network_entity_id = oci_core_service_gateway.main.id
    destination       = data.oci_core_services.main.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "regional" {
  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_block, 8, 0)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, 0)
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.main.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false

  display_name = "${oci_core_vcn.main.display_name}-regional"
}

resource "oci_core_subnet" "public" {
  for_each = { for idx, ad in data.oci_identity_availability_domains.main.availability_domains : ad.name => idx }

  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_block, 8, each.value + 1)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, each.value + 1)
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.main.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  availability_domain        = each.key

  display_name = "${oci_core_vcn.main.display_name}-public-zone-${each.value}"
}

resource "oci_core_subnet" "private" {
  for_each = { for idx, ad in data.oci_identity_availability_domains.main.availability_domains : ad.name => idx }

  cidr_block                 = cidrsubnet(oci_core_vcn.main.cidr_block, 8, each.value + 4)
  ipv6cidr_block             = cidrsubnet(oci_core_vcn.main.ipv6cidr_blocks[0], 8, each.value + 4)
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  route_table_id             = oci_core_route_table.private.id
  prohibit_public_ip_on_vnic = true
  availability_domain        = each.key

  display_name = "${oci_core_vcn.main.display_name}-private-zone-${each.value}"
}
