
variable "vultr_api_key" {
  type = string
  default = ""
}

variable "vultr_region" {
  type = string
  default = ""
}

variable "talos_version" {
  type    = string
  default = "v0.13.0"
}

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/vultr-amd64.raw.xz"
}
