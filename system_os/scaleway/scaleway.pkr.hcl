
packer {
  required_plugins {
    scaleway = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/scaleway"
    }
  }
}

variable "scaleway_project_id" {
  type      = string
  default   = "${env("SCW_DEFAULT_PROJECT_ID")}"
}

variable "scaleway_access_key" {
  type      = string
  default   = "${env("SCW_ACCESS_KEY")}"
  sensitive = true
}

variable "scaleway_secret_key" {
  type      = string
  default   = "${env("SCW_SECRET_KEY")}"
  sensitive = true
}

variable "scaleway_zone" {
  type      = string
  default   = "fr-par-2"
}

variable "talos_version" {
  type    = string
  default = "v0.11.0"
}

source "scaleway" "talos" {
  project_id = var.scaleway_project_id
  access_key = var.scaleway_access_key
  secret_key = var.scaleway_secret_key

  image           = "debian_buster"
  zone            = var.scaleway_zone
  commercial_type = "DEV1-S"
  boottype        = "rescue"
  remove_volume   = true

  ssh_username = "root"

  snapshot_name    = "talos system disk"
}

build {
  sources = ["source.scaleway.talos"]
  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.tar.gz https://github.com/talos-systems/talos/releases/download/${var.talos_version}/metal-amd64.tar.gz",
      "tar xOzf /tmp/talos.tar.gz | dd of=/dev/vda",
    ]
  }
}
