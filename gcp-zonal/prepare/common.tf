
data "google_compute_zones" "region" {
  project = var.project
  region  = var.region
}
