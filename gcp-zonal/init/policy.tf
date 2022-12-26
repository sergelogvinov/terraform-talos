
resource "google_project_iam_custom_role" "ccm" {
  project     = var.project
  role_id     = "KubeCCM"
  title       = "Kubernetes CCM role"
  description = "This is a kubernetes role for CCM, created via Terraform"
  permissions = [
    "compute.instances.list",
    "compute.instances.get",
  ]
}

resource "google_project_iam_custom_role" "csi" {
  project     = var.project
  role_id     = "KubeCsiDriver"
  title       = "Kubernetes csi role"
  description = "This is a kubernetes role for CSI, created via Terraform"
  permissions = [
    "compute.zones.list",
    "compute.instances.get",
    "compute.instances.attachDisk",
    "compute.instances.detachDisk",
    "compute.disks.list",
    "compute.disks.get",
    "compute.zoneOperations.get",
    "compute.zoneOperations.list",
  ]
}

resource "google_project_iam_custom_role" "autoscaler" {
  project     = var.project
  role_id     = "KubeClusterAutoscaler"
  title       = "Kubernetes node autoscale role"
  description = "This is a kubernetes role for node autoscaler system, created via Terraform"
  permissions = [
    "compute.instanceGroupManagers.get",
    "compute.instanceGroupManagers.list",
    "compute.instanceGroupManagers.update",
    "compute.instanceTemplates.get",
    "compute.instanceTemplates.list",
    "compute.machineTypes.get",
    "compute.machineTypes.list",
    "compute.healthChecks.get",
    "compute.httpsHealthChecks.get",
    "servicemanagement.services.get",
    "servicemanagement.services.list",
  ]
}
