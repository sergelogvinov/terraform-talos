
resource "google_storage_bucket_object" "talos" {
  for_each = toset(["amd64", "arm64"])
  name     = "talos-${each.value}.tar.gz"
  source   = "gcp-${each.value}.tar.gz"
  bucket   = google_storage_bucket.images.name
}

resource "google_compute_image" "talos" {
  for_each    = toset(["amd64", "arm64"])
  name        = "talos-${each.value}"
  project     = var.project
  description = "Talos ${var.talos_version}"
  family      = "talos-${each.value}"
  labels = {
    version = "talos"
    arch    = each.value
  }

  raw_disk {
    source = google_storage_bucket_object.talos[each.value].self_link
    sha1   = filesha1("gcp-${each.value}.tar.gz")
  }

  guest_os_features {
    type = "UEFI_COMPATIBLE"
  }
  guest_os_features {
    type = "MULTI_IP_SUBNET"
  }
  # guest_os_features {
  #   type = "GVNIC"
  # }

  depends_on = [google_storage_bucket_object.talos]
}
