
packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "google_account" {
  type      = string
  default   = ""
  sensitive = true
}

variable "google_project" {
  type      = string
  default   = ""
  sensitive = true
}

variable "google_locations" {
  type      = list(string)
  default   = ["europe-west4"]
  sensitive = true
}

variable "talos_version" {
  type    = string
  default = "v0.11.4"
}

source "googlecompute" "talos" {
  account_file        = var.google_account
  project_id          = var.google_project
  zone                = "europe-west4-a"
  subnetwork          = "default"
  source_image_family = "debian-10"
  ssh_username        = "debian"

  machine_type = "e2-small"
  disk_size    = 10
  disk_type    = "pd-standard"

  image_name              = "talos"
  image_description       = "talos system disk"
  image_family            = "talos"
  image_licenses          = ["projects/vm-options/global/licenses/enable-vmx"]
  image_storage_locations = var.google_locations
}

build {
  sources = ["source.googlecompute.talos"]
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y wget",
      "wget -O /tmp/talos.tar.gz https://github.com/talos-systems/talos/releases/download/${var.talos_version}/gcp-amd64.tar.gz",
      "tar xOzf /tmp/talos.tar.gz | sudo dd of=/dev/sda",
    ]
  }
}
