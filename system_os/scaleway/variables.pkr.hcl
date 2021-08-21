
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

variable "talos_version" {
  type    = string
  default = "v0.12.0"
}

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/metal-amd64.tar.gz"
}
