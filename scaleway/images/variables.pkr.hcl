
variable "scaleway_project_id" {
  type    = string
  default = env("SCW_DEFAULT_PROJECT_ID")
}

variable "scaleway_access_key" {
  type      = string
  default   = env("SCW_ACCESS_KEY")
  sensitive = true
}

variable "scaleway_secret_key" {
  type      = string
  default   = env("SCW_SECRET_KEY")
  sensitive = true
}

variable "scaleway_zone" {
  type    = string
  default = "fr-par-2"
}

variable "scaleway_type" {
  type    = string
  default = "COPARM1-2C-8G"
  # default = "DEV1-M"
}

variable "talos_version" {
  type    = string
  default = "v1.8.0"
}

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/scaleway-$ARCH.raw.xz"
}
