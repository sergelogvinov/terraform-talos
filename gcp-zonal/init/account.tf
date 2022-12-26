
resource "google_service_account" "terraform" {
  project      = var.project
  account_id   = "terraform"
  display_name = "Terraform Service Account"
}

resource "google_service_account_iam_member" "terraform" {
  service_account_id = google_service_account.terraform.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_project_iam_binding" "terraform" {
  project = var.project
  role    = "roles/editor"

  members = [
    "serviceAccount:${google_service_account.terraform.email}",
  ]
}

resource "google_project_iam_binding" "terraform_networksAdmin" {
  project = var.project
  role    = "roles/servicenetworking.networksAdmin"

  members = [
    "serviceAccount:${google_service_account.terraform.email}",
  ]

  # condition {
  #   title       = "ExpiresAfter_2023_12_31"
  #   description = "Expiring at midnight of 2023-12-31"
  #   expression  = "request.time < timestamp(\"2023-01-30T22:00:00.000Z\")"
  # }
}

resource "google_project_iam_binding" "terraform_saAdmin" {
  project = var.project
  role    = "roles/iam.serviceAccountAdmin"

  members = [
    "serviceAccount:${google_service_account.terraform.email}",
  ]
}

resource "google_project_iam_binding" "terraform_iamAdmin" {
  project = var.project
  role    = "roles/iam.securityAdmin"

  members = [
    "serviceAccount:${google_service_account.terraform.email}",
  ]
}
