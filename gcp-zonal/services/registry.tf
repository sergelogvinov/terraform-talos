
resource "google_container_registry" "registry" {
  project  = var.project_id
  location = "EU"
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_container_registry.registry.id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_client_openid_userinfo.terraform.email}"
}
