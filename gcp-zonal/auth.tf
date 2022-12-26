
provider "google" {
  project = local.project
  region  = local.region
}

# provider "google-beta" {
#   project     = var.project_id
#   region      = var.region
# }

# data "google_client_config" "default" {}
