
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

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/upcloud-amd64.raw.xz"
}
