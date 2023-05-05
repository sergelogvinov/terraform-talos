
variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}

variable "hcloud_location" {
  type      = string
  default   = "fsn1"
}

variable "hcloud_type" {
  type      = string
  default   = "cx11" # cx11|cax11 (arm)
}

variable "talos_version" {
  type    = string
  default = "v1.4.1"
}

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/hcloud-$ARCH.raw.xz"
}
