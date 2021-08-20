
variable "hcloud_token" {
  type      = string
  default   = env("HCLOUD_TOKEN")
  sensitive = true
}

variable "talos_version" {
  type    = string
  default = "v0.12.0"
}

locals {
  image = "https://github.com/talos-systems/talos/releases/download/${var.talos_version}/openstack-amd64.tar.gz"
}
