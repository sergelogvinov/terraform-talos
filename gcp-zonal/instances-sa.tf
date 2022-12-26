
resource "google_service_account" "controlplane" {
  account_id   = "controlplane"
  display_name = "A service account for controlplane instances"
}

# resource "google_project_iam_member" "ccm_sa" {
#   project = local.project
#   role    = "roles/compute.serviceAgent"
#   member  = "serviceAccount:${google_service_account.controlplane.email}"
# }

resource "google_project_iam_member" "ccm" {
  project = local.project
  role    = "projects/${local.project}/roles/KubeCCM"
  member  = "serviceAccount:${google_service_account.controlplane.email}"
}

# resource "google_project_iam_member" "ccm_autoscaler" {
#   project = local.project
#   role    = "projects/${local.project}/roles/KubeClusterAutoscaler"
#   member  = "serviceAccount:${google_service_account.controlplane.email}"
# }

# resource "google_project_iam_member" "ccm_autoscaler_roles" {
#   project = local.project
#   role    = "roles/viewer"
#   member  = "serviceAccount:${google_service_account.controlplane.email}"
# }


# resource "google_service_account" "csi" {
#   account_id   = "csi-driver"
#   display_name = "A service account for csi-driver"
# }

# resource "google_project_iam_member" "csi" {
#   project = local.project
#   role    = "projects/${local.project}/roles/KubeCsiDriver"
#   member  = "serviceAccount:${google_service_account.csi.email}"
# }

# resource "google_project_iam_member" "csi_storageAdmin" {
#   project = local.project
#   role    = "roles/compute.storageAdmin"
#   member  = "serviceAccount:${google_service_account.csi.email}"
# }

# resource "google_project_iam_member" "csi_serviceAccountUser" {
#   project = local.project
#   role    = "roles/iam.serviceAccountUser"
#   member  = "serviceAccount:${google_service_account.csi.email}"
# }

resource "google_service_account" "autoscaler" {
  account_id   = "cluster-autoscale"
  display_name = "A service account for cluster-autoscale"
}

resource "google_project_iam_member" "autoscaler" {
  project = local.project
  role    = "projects/${local.project}/roles/KubeClusterAutoscaler"
  member  = "serviceAccount:${google_service_account.autoscaler.email}"
}

resource "google_project_iam_member" "autoscaler_admin" {
  project = local.project
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.autoscaler.email}"
}

resource "google_project_iam_member" "autoscaler_roles" {
  project = local.project
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.autoscaler.email}"
}
