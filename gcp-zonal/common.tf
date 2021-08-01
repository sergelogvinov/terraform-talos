
data "google_client_openid_userinfo" "terraform" {}

resource "google_os_login_ssh_public_key" "terraform" {
  project = var.project_id
  user    = data.google_client_openid_userinfo.terraform.email
  key     = file("~/.ssh/terraform.pub")
}

# resource "google_compute_image" "talos" {
#   name        = "talos"
#   description = "Talos v0.11.3"

#   raw_disk {
#     source = "https://github.com/talos-systems/talos/releases/download/v0.11.3/gcp-amd64.tar.gz"
#   }

#   guest_os_features {
#     type = "VIRTIO_SCSI_MULTIQUEUE"
#   }
#   guest_os_features {
#     type = "MULTI_IP_SUBNET"
#   }
# }

data "google_compute_image" "talos" {
  project = var.project_id
  family  = "talos"
}
