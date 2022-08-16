
provider "scaleway" {
  access_key = var.scaleway_access
  secret_key = var.scaleway_secret
  project_id = var.scaleway_project_id
  region     = substr(var.regions[0], 0, 6)
  zone       = var.regions[0]
}
