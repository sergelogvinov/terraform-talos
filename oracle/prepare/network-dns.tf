
data "oci_core_vcn_dns_resolver_association" "main" {
  vcn_id = oci_core_vcn.main.id
}

data "oci_dns_resolver" "main" {
  resolver_id = data.oci_core_vcn_dns_resolver_association.main.dns_resolver_id
  scope       = "PRIVATE"
}

resource "oci_dns_zone" "cluster" {
  compartment_id = var.compartment_ocid
  name           = var.kubernetes["domain"]
  zone_type      = "PRIMARY"
  scope          = "PRIVATE"
  view_id        = data.oci_dns_resolver.main.default_view_id
}
