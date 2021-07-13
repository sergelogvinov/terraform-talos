
packer {
  required_plugins {
    upcloud = {
      version = ">= 1.0.0"
      source  = "github.com/UpCloudLtd/upcloud"
    }
  }
}

variable "upcloud_username" {
  type = string
  default = ""
}

variable "upcloud_password" {
  type = string
  default = ""
  sensitive = true
}

variable "upcloud_zone" {
  type      = string
  default   = "nl-ams1"
}

variable "upcloud_zones" {
  type      = list(string)
  default   = ["de-fra1", "uk-lon1"]
}

variable "talos_version" {
  type    = string
  default = "v0.11.0"
}

source "upcloud" "talos" {
  username = var.upcloud_username
  password = var.upcloud_password
  zone     = var.upcloud_zone

  storage_uuid    = "01000000-0000-4000-8000-000020050100"
  storage_size    = 10
  template_prefix = "talos-system-disk"
  # clone_zones     = var.upcloud_zones
}

build {
  sources = ["source.upcloud.talos"]
  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.tar.gz https://github.com/talos-systems/talos/releases/download/${var.talos_version}/metal-amd64.tar.gz",
      "tar xOzf /tmp/talos.tar.gz | dd of=/dev/vda",
    ]
  }
}
