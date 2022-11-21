
variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}

variable "talos_version" {
  type    = string
  default = "v1.2.6"
}

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/hcloud-amd64.raw.xz"
}
