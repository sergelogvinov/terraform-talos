
data "google_client_openid_userinfo" "terraform" {}

data "google_compute_image" "talos" {
  project = local.project
  family  = "talos-amd64"
}

resource "google_compute_health_check" "instance" {
  name                = "${local.cluster_name}-instance-health-check"
  timeout_sec         = 5
  check_interval_sec  = 30
  healthy_threshold   = 1
  unhealthy_threshold = 10

  tcp_health_check {
    port = "50000"
  }
}
