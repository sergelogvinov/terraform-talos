
# resource "oci_network_load_balancer_network_load_balancer" "contolplane" {
#   compartment_id             = var.compartment_ocid
#   display_name               = "${local.project}-contolplane-lb"
#   subnet_id                  = local.network_lb.id
#   network_security_group_ids = [local.nsg_contolplane_lb]

#   is_preserve_source_destination = false
#   is_private                     = true
# }

# resource "oci_network_load_balancer_listener" "contolplane" {
#   default_backend_set_name = oci_network_load_balancer_backend_set.contolplane.name

#   name                     = "${local.project}-contolplane"
#   network_load_balancer_id = oci_network_load_balancer_network_load_balancer.contolplane.id
#   port                     = 80
#   protocol                 = "TCP"
# }

# resource "oci_network_load_balancer_backend_set" "contolplane" {
#   name                     = "${local.project}-contolplane"
#   network_load_balancer_id = oci_network_load_balancer_network_load_balancer.contolplane.id
#   policy                   = "FIVE_TUPLE"
#   is_preserve_source       = false

#   health_checker {
#     protocol    = "HTTP"
#     port        = 80
#     url_path    = "/"
#     return_code = 200
#   }
# }

# resource "oci_network_load_balancer_network_load_balancer" "web" {
#   compartment_id             = var.compartment_ocid
#   display_name               = "${local.project}-web-lb"
#   subnet_id                  = local.network_lb.id
#   network_security_group_ids = [local.nsg_web]

#   is_preserve_source_destination = false
#   is_private                     = false
# }

# resource "oci_network_load_balancer_listener" "http" {
#   default_backend_set_name = oci_network_load_balancer_backend_set.web_http.name

#   name                     = "${local.project}-web-http"
#   network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web.id
#   port                     = 80
#   protocol                 = "TCP"
# }

# resource "oci_network_load_balancer_listener" "https" {
#   default_backend_set_name = oci_network_load_balancer_backend_set.web_https.name

#   name                     = "${local.project}-web-https"
#   network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web.id
#   port                     = 443
#   protocol                 = "TCP"
# }

# resource "oci_network_load_balancer_backend_set" "web_http" {
#   name                     = "${local.project}-web-http"
#   network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web.id
#   policy                   = "FIVE_TUPLE"
#   is_preserve_source       = true

#   health_checker {
#     interval_in_millis = 30000
#     protocol           = "HTTP"
#     port               = 80
#     url_path           = "/"
#     return_code        = 200
#   }
# }

# resource "oci_network_load_balancer_backend_set" "web_https" {
#   name                     = "${local.project}-web-https"
#   network_load_balancer_id = oci_network_load_balancer_network_load_balancer.web.id
#   policy                   = "FIVE_TUPLE"
#   is_preserve_source       = true

#   health_checker {
#     interval_in_millis = 30000
#     protocol           = "HTTP"
#     port               = 80
#     url_path           = "/"
#     return_code        = 200
#   }
# }
