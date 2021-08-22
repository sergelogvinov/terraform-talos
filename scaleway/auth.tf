
provider "scaleway" {
  access_key = var.scaleway_access
  secret_key = var.scaleway_secret
  project_id = var.scaleway_project_id
  zone       = "fr-par-1"
  region     = "fr-par"
}
