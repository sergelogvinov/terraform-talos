
resource "oci_load_balancer" "web" {
  compartment_id = var.compartment_ocid
  display_name   = "${local.project}-web-lb-l7"
  shape          = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }

  subnet_ids                 = [local.network_lb.id]
  network_security_group_ids = [local.nsg_web]
}

resource "oci_load_balancer_listener" "web_http" {
  load_balancer_id         = oci_load_balancer.web.id
  name                     = "${local.project}-web-http"
  default_backend_set_name = oci_load_balancer_backend_set.web.name
  port                     = 80
  protocol                 = "HTTP"
}

resource "oci_load_balancer_backend_set" "web" {
  name             = "${local.project}-web-lb-l7"
  load_balancer_id = oci_load_balancer.web.id
  policy           = "ROUND_ROBIN"

  health_checker {
    retries     = 2
    protocol    = "HTTP"
    port        = 80
    url_path    = "/healthz"
    return_code = 200
  }
}
