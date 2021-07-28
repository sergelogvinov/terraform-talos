
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = "gcloud.json"
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  credentials = "gcloud.json"
}

data "google_client_config" "default" {}
