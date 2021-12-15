
resource "oci_core_network_security_group" "cilium" {
  display_name   = "${var.project}-cilium"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
}
resource "oci_core_network_security_group_security_rule" "cilium_vxvlan" {
  network_security_group_id = oci_core_network_security_group.cilium.id

  protocol  = "17"
  direction = "INGRESS"
  source    = var.vpc_main_cidr
  stateless = true

  udp_options {
  }
}
resource "oci_core_network_security_group_security_rule" "cilium_health" {
  network_security_group_id = oci_core_network_security_group.cilium.id

  protocol  = "6"
  direction = "INGRESS"
  source    = var.vpc_main_cidr
  stateless = true

  tcp_options {
    destination_port_range {
      min = 4240
      max = 4240
    }
  }
}

resource "oci_core_network_security_group" "talos" {
  display_name   = "${var.project}-talos"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
}

resource "oci_core_network_security_group_security_rule" "talos" {
  network_security_group_id = oci_core_network_security_group.talos.id

  protocol  = "6"
  direction = "INGRESS"
  source    = var.vpc_main_cidr
  stateless = true

  tcp_options {
    destination_port_range {
      min = 50000
      max = 50001
    }
  }
}

resource "oci_core_network_security_group_security_rule" "admin_ssh" {
  network_security_group_id = oci_core_network_security_group.talos.id

  protocol  = "6"
  direction = "INGRESS"
  source    = var.vpc_main_cidr
  stateless = true

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group" "contolplane_lb" {
  display_name   = "${var.project}-contolplane-lb"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
}

resource "oci_core_network_security_group_security_rule" "kubernetes" {
  network_security_group_id = oci_core_network_security_group.contolplane_lb.id

  protocol  = "6"
  direction = "INGRESS"
  source    = var.vpc_main_cidr
  stateless = true

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group" "contolplane" {
  display_name   = "${var.project}-contolplane"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
}
resource "oci_core_network_security_group_security_rule" "contolplane_kubernetes" {
  network_security_group_id = oci_core_network_security_group.contolplane.id

  protocol  = "6"
  direction = "INGRESS"
  source    = "0.0.0.0/0"
  stateless = true

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}
resource "oci_core_network_security_group_security_rule" "contolplane_etcd" {
  network_security_group_id = oci_core_network_security_group.contolplane.id

  protocol  = "6"
  direction = "INGRESS"
  source    = var.vpc_main_cidr
  stateless = true

  tcp_options {
    destination_port_range {
      min = 2379
      max = 2380
    }
  }
}

resource "oci_core_network_security_group" "web" {
  display_name   = "${var.project}-web"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
}
resource "oci_core_network_security_group_security_rule" "web_http" {
  network_security_group_id = oci_core_network_security_group.web.id

  protocol  = "6"
  direction = "INGRESS"
  source    = "0.0.0.0/0"
  stateless = true

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}
resource "oci_core_network_security_group_security_rule" "web_https" {
  network_security_group_id = oci_core_network_security_group.web.id

  protocol  = "6"
  direction = "INGRESS"
  source    = "0.0.0.0/0"
  stateless = true

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}
