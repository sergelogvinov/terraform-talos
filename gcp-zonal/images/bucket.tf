
resource "random_id" "backet" {
  byte_length = 8
}

resource "google_storage_bucket" "images" {
  name                        = "images-${random_id.backet.hex}"
  project                     = var.project
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

data "google_client_openid_userinfo" "terraform" {}

resource "google_storage_bucket_iam_binding" "terraform" {
  bucket = google_storage_bucket.images.name
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${data.google_client_openid_userinfo.terraform.email}",
  ]
}
