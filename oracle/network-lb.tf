
locals {
  lbv4_enable = false
  lbv4        = local.lbv4_enable ? [for ip in oci_network_load_balancer_network_load_balancer.contolplane[0].ip_addresses : ip.ip_address if ip.is_public][0] : "127.0.0.1"
  lbv4_local  = local.lbv4_enable ? [for ip in oci_network_load_balancer_network_load_balancer.contolplane[0].ip_addresses : ip.ip_address if !ip.is_public][0] : cidrhost(local.network_public[local.zone].cidr_block, 11)

  lbv4_web_enable = false
  lbv4_web        = local.lbv4_web_enable ? [for ip in oci_network_load_balancer_network_load_balancer.web[0].ip_addresses : ip.ip_address if ip.is_public][0] : "127.0.0.1"
}

resource "oci_dns_rrset" "lbv4_local" {
  zone_name_or_id = local.dns_zone_id
  domain          = var.kubernetes["apiDomain"]
  rtype           = "A"

  items {
    domain = var.kubernetes["apiDomain"]
    rdata  = local.lbv4_local
    rtype  = "A"
    ttl    = 3600
  }
}

resource "oci_network_load_balancer_network_load_balancer" "contolplane" {
  count                      = local.lbv4_enable ? 1 : 0
  compartment_id             = var.compartment_ocid
  display_name               = "${local.project}-contolplane-lb"
  subnet_id                  = local.network_lb.id
  network_security_group_ids = [local.nsg_contolplane_lb]

  is_preserve_source_destination = false
  is_private                     = false
}

resource "oci_network_load_balancer_listener" "contolplane" {
  count                    = local.lbv4_enable ? 1 : 0
  default_backend_set_name = oci_network_load_balancer_backend_set.contolplane[0].name

  name                     = "${local.project}-contolplane"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.contolplane[0].id
  port                     = 6443
  protocol                 = "TCP"
}
resource "oci_network_load_balancer_listener" "contolplane_talos" {
  count                    = local.lbv4_enable ? 1 : 0
  default_backend_set_name = oci_network_load_balancer_backend_set.contolplane_talos[0].name

  name                     = "${local.project}-contolplane-talos"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.contolplane[0].id
  port                     = 50000
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "contolplane" {
  count                    = local.lbv4_enable ? 1 : 0
  name                     = "${local.project}-contolplane"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.contolplane[0].id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = false

  health_checker {
    protocol           = "HTTPS"
    port               = 6443
    url_path           = "/readyz"
    return_code        = 200
    interval_in_millis = 15000
  }
}
resource "oci_network_load_balancer_backend_set" "contolplane_talos" {
  count                    = local.lbv4_enable ? 1 : 0
  name                     = "${local.project}-contolplane-talos"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.contolplane[0].id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = false

  health_checker {
    protocol           = "TCP"
    port               = 50000
    interval_in_millis = 30000
  }
}

resource "oci_dns_rrset" "lbv4_web" {
  zone_name_or_id = local.dns_zone_id
  domain          = var.kubernetes["domain"]
  rtype           = "A"

  items {
    domain = var.kubernetes["domain"]
    rdata  = local.lbv4_web
    rtype  = "A"
    ttl    = 3600
  }
}

resource "oci_network_load_balancer_network_load_balancer" "web" {
  count                      = local.lbv4_web_enable ? 1 : 0
  compartment_id             = var.compartment_ocid
  display_name               = "${local.project}-web-lb"
  subnet_id                  = local.network_lb.id
  network_security_group_ids = [local.nsg_web]

  is_preserve_source_destination = false
  is_private                     = false
}

resource "oci_network_load_balancer_listener" "http" {
  count                    = local.lbv4_web_enable ? 1 : 0
  default_backend_set_name = oci_network_load_balancer_backend_set.web_http[0].name

  name                     = "${local.project}-web-http"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web[0].id
  port                     = 80
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "web_http" {
  count                    = local.lbv4_web_enable ? 1 : 0
  name                     = "${local.project}-web-http"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web[0].id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    retries            = 2
    interval_in_millis = 15000
    protocol           = "HTTP"
    port               = 80
    url_path           = "/healthz"
    return_code        = 200
  }
}

resource "oci_network_load_balancer_listener" "https" {
  count                    = local.lbv4_web_enable ? 1 : 0
  default_backend_set_name = oci_network_load_balancer_backend_set.web_https[0].name

  name                     = "${local.project}-web-https"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web[0].id
  port                     = 443
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "web_https" {
  count                    = local.lbv4_web_enable ? 1 : 0
  name                     = "${local.project}-web-https"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web[0].id
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true

  health_checker {
    interval_in_millis = 15000
    protocol           = "HTTP"
    port               = 80
    url_path           = "/healthz"
    return_code        = 200
  }
}
